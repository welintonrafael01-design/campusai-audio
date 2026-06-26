import 'package:flutter/material.dart';

import '../layout/responsive_layout.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/voice_intelligence/ai_coach_service.dart';
import '../services/voice_intelligence/voice_context_service.dart';
import '../services/voice_intelligence/voice_memory_service.dart';
import '../services/voice_intelligence/voice_models.dart';
import '../services/voice_intelligence/voice_session_service.dart';
import '../services/voice_intelligence/voice_tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class VoiceTutorScreen extends StatefulWidget {
  final String audiobookId;
  final String chapterId;
  final String title;
  final String sessionId;
  final Map<String, dynamic> payload;

  const VoiceTutorScreen({
    super.key,
    this.audiobookId = '',
    this.chapterId = '',
    this.title = '',
    this.sessionId = '',
    this.payload = const {},
  });

  @override
  State<VoiceTutorScreen> createState() => _VoiceTutorScreenState();
}

class _VoiceTutorScreenState extends State<VoiceTutorScreen> {
  final sessionService = const VoiceSessionService();
  final contextService = const VoiceContextService();
  final memoryService = const VoiceMemoryService();
  final coachService = const AiCoachService();
  final voiceTtsService = const VoiceTtsService();
  final audioPlayerService = AudioPlayerService();
  final messageController = TextEditingController();

  bool isLoading = true;
  bool isSending = false;
  String errorMessage = '';
  final Set<String> generatingAudioMessageIds = {};

  VoiceSession session = VoiceSession.empty();
  VoiceContext voiceContext = VoiceContext.empty;
  List<VoiceMessage> messages = [];
  List<String> suggestions = const [];
  List<String> followUpQuestions = const [];

  @override
  void initState() {
    super.initState();
    loadTutor();
  }

  @override
  void dispose() {
    messageController.dispose();
    audioPlayerService.dispose();
    super.dispose();
  }

  Future<void> loadTutor() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final loadedContext = await contextService.buildContext(
        audiobookId: widget.audiobookId,
        chapterId: widget.chapterId,
        extra: widget.payload,
      );
      final loadedSession = await _loadOrCreateSession(loadedContext);
      final recentMessages = await memoryService.recentMessages(
        audiobookId: loadedContext.audiobookId,
        chapterId: loadedContext.chapterId,
      );

      if (!mounted) return;

      setState(() {
        voiceContext = loadedContext;
        session = loadedSession;
        messages = loadedSession.messages.isNotEmpty
            ? loadedSession.messages
            : recentMessages;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'No se pudo contactar al tutor. Inténtalo nuevamente.';
        isLoading = false;
      });
    }
  }

  Future<VoiceSession> _loadOrCreateSession(VoiceContext context) async {
    final cleanSessionId = widget.sessionId.trim();
    if (cleanSessionId.isNotEmpty) {
      final existing = await sessionService.getSession(cleanSessionId);
      if (existing != null) return existing;
    }

    return sessionService.createSession(
      audiobookId: context.audiobookId,
      chapterId: context.chapterId,
      title: widget.title.trim().isNotEmpty
          ? widget.title.trim()
          : context.chapterTitle.trim().isNotEmpty
              ? 'Tutor IA - ${context.chapterTitle}'
              : 'Tutor IA',
    );
  }

  Future<void> sendMessage({
    String? text,
    String mode = 'general',
  }) async {
    final content = (text ?? messageController.text).trim();
    if (content.isEmpty || isSending) return;

    messageController.clear();

    final userMessage = sessionService.createMessage(
      role: 'user',
      content: content,
      metadata: {'mode': mode},
    );

    setState(() {
      isSending = true;
      errorMessage = '';
      messages = [...messages, userMessage];
    });

    try {
      final userSession = await sessionService.addMessage(
        session: session,
        message: userMessage,
      );
      final response = await coachService.askCoach(
        userMessage: content,
        context: voiceContext,
        recentMessages: messages,
        mode: mode,
      );
      final assistantMessage = sessionService.createMessage(
        role: 'assistant',
        content: response.text,
        metadata: response.toJson(),
      );
      final updatedSession = await sessionService.addMessage(
        session: userSession,
        message: assistantMessage,
      );

      if (!mounted) return;

      setState(() {
        session = updatedSession;
        messages = updatedSession.messages;
        suggestions = response.suggestions;
        followUpQuestions = response.followUpQuestions;
        isSending = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'No se pudo contactar al tutor. Inténtalo nuevamente.';
        isSending = false;
      });
    }
  }

  Future<void> generateAudioForAssistantMessage(VoiceMessage message) async {
    if (message.role != 'assistant') return;
    if (generatingAudioMessageIds.contains(message.messageId)) return;

    setState(() {
      generatingAudioMessageIds.add(message.messageId);
    });

    try {
      final updatedMessage = await voiceTtsService.generateAudioForMessage(
        message: message,
        voiceProfile: 'standard',
        language: 'es',
      );

      final updatedSession = _sessionWithMessage(updatedMessage);
      await sessionService.saveSession(updatedSession);

      if (!mounted) return;

      setState(() {
        session = updatedSession;
        messages = _replaceMessage(messages, updatedMessage);
        generatingAudioMessageIds.remove(message.messageId);
      });

      if (!voiceTtsService.hasAudio(updatedMessage)) {
        _showSnackBar('No se pudo generar audio para esta respuesta.');
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        generatingAudioMessageIds.remove(message.messageId);
      });
      _showSnackBar('No se pudo generar audio para esta respuesta.');
    }
  }

  Future<void> playAssistantAudio(VoiceMessage message) async {
    final audioUrl = voiceTtsService.audioUrl(message);
    if (audioUrl.isEmpty) {
      _showSnackBar('Esta respuesta todavía no tiene audio.');
      return;
    }

    try {
      await audioPlayerService.play(ApiService.buildAudioUrl(audioUrl));
    } catch (_) {
      if (!mounted) return;

      _showSnackBar(
        'No se pudo reproducir el audio. Puedes leer la respuesta en pantalla.',
      );
    }
  }

  VoiceSession _sessionWithMessage(VoiceMessage updatedMessage) {
    final sessionMessages = _replaceMessage(session.messages, updatedMessage);
    final exists = session.messages.any(
      (message) => message.messageId == updatedMessage.messageId,
    );

    return session.copyWith(
      updatedAt: DateTime.now(),
      messages:
          exists ? sessionMessages : [...session.messages, updatedMessage],
    );
  }

  List<VoiceMessage> _replaceMessage(
    List<VoiceMessage> source,
    VoiceMessage updatedMessage,
  ) {
    var replaced = false;
    final updated = source.map((message) {
      if (message.messageId != updatedMessage.messageId) return message;
      replaced = true;
      return updatedMessage;
    }).toList();

    return replaced ? updated : [...source, updatedMessage];
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor IA'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(isMobile ? 16 : 22),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 980),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ContextHeader(context: voiceContext),
                                const SizedBox(height: 16),
                                _QuickActions(onAction: sendMessage),
                                if (errorMessage.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _ErrorCard(message: errorMessage),
                                ],
                                const SizedBox(height: 16),
                                _MessageList(
                                  messages: messages,
                                  generatingAudioMessageIds:
                                      generatingAudioMessageIds,
                                  hasAudio: voiceTtsService.hasAudio,
                                  durationSeconds:
                                      voiceTtsService.durationSeconds,
                                  onGenerateAudio:
                                      generateAudioForAssistantMessage,
                                  onPlayAudio: playAssistantAudio,
                                ),
                                if (suggestions.isNotEmpty ||
                                    followUpQuestions.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _Suggestions(
                                    suggestions: suggestions,
                                    followUpQuestions: followUpQuestions,
                                    onTap: (value) => sendMessage(text: value),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Composer(
                    controller: messageController,
                    isSending: isSending,
                    onSend: () => sendMessage(),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ContextHeader extends StatelessWidget {
  final VoiceContext context;

  const _ContextHeader({required this.context});

  @override
  Widget build(BuildContext context) {
    final title = this.context.audiobookTitle.trim().isEmpty
        ? 'Tutor IA'
        : this.context.audiobookTitle;
    final chapter = this.context.chapterTitle.trim().isEmpty
        ? 'Modo general'
        : this.context.chapterTitle;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tutor IA',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chapter,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Dominio ${this.context.mastery}%')),
              if (this.context.keyConcepts.isNotEmpty)
                Chip(
                  label: Text(
                    'Conceptos: ${this.context.keyConcepts.take(2).join(', ')}',
                  ),
                ),
              if (this.context.recommendations.isNotEmpty)
                Chip(label: Text(this.context.recommendations.first)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'TODO Voice Intelligence 3.0: STT, botón micrófono, transcripción, conversación por voz, interrupciones y streaming.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final Future<void> Function({String? text, String mode}) onAction;

  const _QuickActions({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _ActionButton(
            label: 'Explícame mejor',
            mode: 'explain',
            text: 'Explícame mejor este capítulo paso a paso.',
            onAction: onAction,
          ),
          _ActionButton(
            label: 'Hazme preguntas',
            mode: 'quiz',
            text: 'Hazme preguntas para practicar.',
            onAction: onAction,
          ),
          _ActionButton(
            label: 'Dame un ejemplo',
            mode: 'explain',
            text: 'Dame un ejemplo aplicado de este tema.',
            onAction: onAction,
          ),
          _ActionButton(
            label: 'Resume',
            mode: 'review',
            text: 'Resume lo más importante.',
            onAction: onAction,
          ),
          _ActionButton(
            label: 'Motívame',
            mode: 'motivate',
            text: 'Motívame para continuar estudiando.',
            onAction: onAction,
          ),
          _ActionButton(
            label: 'Evalúame oralmente próximamente',
            mode: 'quiz',
            text: 'Prepárame una evaluación oral para practicar próximamente.',
            onAction: onAction,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final String mode;
  final String text;
  final Future<void> Function({String? text, String mode}) onAction;

  const _ActionButton({
    required this.label,
    required this.mode,
    required this.text,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => onAction(text: text, mode: mode),
      child: Text(label),
    );
  }
}

class _MessageList extends StatelessWidget {
  final List<VoiceMessage> messages;
  final Set<String> generatingAudioMessageIds;
  final bool Function(VoiceMessage message) hasAudio;
  final int Function(VoiceMessage message) durationSeconds;
  final ValueChanged<VoiceMessage> onGenerateAudio;
  final ValueChanged<VoiceMessage> onPlayAudio;

  const _MessageList({
    required this.messages,
    required this.generatingAudioMessageIds,
    required this.hasAudio,
    required this.durationSeconds,
    required this.onGenerateAudio,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const SectionCard(
        child: Text(
          'Hazme una pregunta sobre este capítulo.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return Column(
      children: [
        for (final message in messages)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MessageBubble(
              message: message,
              isGeneratingAudio:
                  generatingAudioMessageIds.contains(message.messageId),
              hasAudio: hasAudio(message),
              durationSeconds: durationSeconds(message),
              onGenerateAudio: () => onGenerateAudio(message),
              onPlayAudio: () => onPlayAudio(message),
            ),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final VoiceMessage message;
  final bool isGeneratingAudio;
  final bool hasAudio;
  final int durationSeconds;
  final VoidCallback onGenerateAudio;
  final VoidCallback onPlayAudio;

  const _MessageBubble({
    required this.message,
    required this.isGeneratingAudio,
    required this.hasAudio,
    required this.durationSeconds,
    required this.onGenerateAudio,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final suggestions = _stringList(message.metadata['suggestions']);
    final followUps = _stringList(message.metadata['follow_up_questions']);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser
                ? AppTheme.primary.withValues(alpha: 0.18)
                : AppTheme.cardSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'Tú' : 'Tutor IA',
                  style: TextStyle(
                    color: isUser ? AppTheme.accent : AppTheme.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message.content,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (!isUser) ...[
                  if (suggestions.isNotEmpty || followUps.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InlinePromptGroup(
                      title: 'Sugerencias',
                      values: suggestions,
                    ),
                    _InlinePromptGroup(
                      title: 'Preguntas de seguimiento',
                      values: followUps,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (hasAudio)
                        Chip(
                          label: Text(
                            durationSeconds > 0
                                ? 'Audio listo · ${durationSeconds}s'
                                : 'Audio listo',
                          ),
                        )
                      else
                        const Chip(label: Text('Audio pendiente')),
                      OutlinedButton.icon(
                        onPressed: isGeneratingAudio ? null : onGenerateAudio,
                        icon: isGeneratingAudio
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.graphic_eq_rounded),
                        label: Text(
                          isGeneratingAudio
                              ? 'Generando audio...'
                              : 'Generar audio',
                        ),
                      ),
                      if (hasAudio)
                        FilledButton.icon(
                          onPressed: onPlayAudio,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Escuchar'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlinePromptGroup extends StatelessWidget {
  final String title;
  final List<String> values;

  const _InlinePromptGroup({
    required this.title,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values.take(3))
                Chip(
                  label: Text(value),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.10),
                  side: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.14),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  final List<String> suggestions;
  final List<String> followUpQuestions;
  final ValueChanged<String> onTap;

  const _Suggestions({
    required this.suggestions,
    required this.followUpQuestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final values = [...suggestions, ...followUpQuestions]
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(5)
        .toList();

    return SectionCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final value in values)
            ActionChip(
              label: Text(value),
              onPressed: () => onTap(value),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => isSending ? null : onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu pregunta para el Tutor IA...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: isSending ? null : onSend,
                icon: isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('Enviar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _stringList(dynamic raw) {
  if (raw is List) {
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  final text = raw?.toString().trim() ?? '';
  return text.isEmpty ? <String>[] : <String>[text];
}
