import 'package:flutter/material.dart';

import '../layout/responsive_layout.dart';
import '../services/voice_intelligence/ai_coach_service.dart';
import '../services/voice_intelligence/voice_context_service.dart';
import '../services/voice_intelligence/voice_memory_service.dart';
import '../services/voice_intelligence/voice_models.dart';
import '../services/voice_intelligence/voice_session_service.dart';
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
  final messageController = TextEditingController();

  bool isLoading = true;
  bool isSending = false;
  String errorMessage = '';

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
                                _MessageList(messages: messages),
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
            'MVP textual. TODO v2: capturar voz, STT, leer respuesta con TTS, interrupciones y streaming.',
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
            label: 'Explícame',
            mode: 'explain',
            text: 'Explícame este capítulo paso a paso.',
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

  const _MessageList({required this.messages});

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
            child: _MessageBubble(message: message),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final VoiceMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

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
              ],
            ),
          ),
        ),
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
