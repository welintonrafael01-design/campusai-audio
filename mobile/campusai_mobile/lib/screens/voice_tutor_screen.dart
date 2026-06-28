import 'dart:async';

import 'package:flutter/material.dart';

import '../layout/responsive_layout.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/learning_engine/learning_session_service.dart';
import '../services/voice_intelligence/ai_coach_service.dart';
import '../services/voice_intelligence/voice_conversation_service.dart';
import '../services/voice_intelligence/voice_context_service.dart';
import '../services/voice_intelligence/voice_memory_service.dart';
import '../services/voice_intelligence/voice_models.dart';
import '../services/voice_intelligence/voice_session_service.dart';
import '../services/voice_intelligence/voice_tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/studybook/booky_card.dart';
import '../widgets/studybook/studybook_states.dart';

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
  final conversationService = VoiceConversationService();
  final learningSessionService = const LearningSessionService();
  final audioPlayerService = AudioPlayerService();
  final messageController = TextEditingController();
  StreamSubscription<dynamic>? tutorAudioSubscription;

  bool isLoading = true;
  bool isSending = false;
  bool isProcessingVoiceInput = false;
  bool isSpeaking = false;
  String errorMessage = '';
  String lastHandledVoiceText = '';
  final Set<String> generatingAudioMessageIds = {};

  VoiceSession session = VoiceSession.empty();
  VoiceContext voiceContext = VoiceContext.empty;
  VoiceConversationState conversationState = VoiceConversationState.idleState;
  List<VoiceMessage> messages = [];
  List<String> suggestions = const [];
  List<String> followUpQuestions = const [];

  @override
  void initState() {
    super.initState();
    tutorAudioSubscription = audioPlayerService.playerStateStream.listen(
      (state) {
        if (!mounted) return;

        setState(() {
          isSpeaking = state.playing;
        });
      },
    );
    loadTutor();
  }

  @override
  void dispose() {
    unawaited(
      conversationService.release(),
    );
    unawaited(tutorAudioSubscription?.cancel());
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
    String inputMode = 'text',
    Map<String, dynamic> metadata = const {},
    bool autoGenerateAudio = false,
  }) async {
    final content = (text ?? messageController.text).trim();
    if (content.isEmpty || isSending) return;

    messageController.clear();
    final processingStartedAt = DateTime.now();

    final userMessage = sessionService.createMessage(
      role: 'user',
      content: content,
      metadata: {
        'mode': mode,
        'input_mode': inputMode,
        ...metadata,
      },
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
        metadata: {
          ...response.toJson(),
          'input_mode': 'assistant',
          'conversation_turn': metadata['conversation_turn'],
          'processing_time':
              DateTime.now().difference(processingStartedAt).inMilliseconds /
                  1000,
        },
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

      VoiceMessage finalAssistantMessage = assistantMessage;
      if (autoGenerateAudio) {
        final generated = await generateAudioForAssistantMessage(
          assistantMessage,
          autoPlay: true,
        );
        finalAssistantMessage = generated ?? assistantMessage;
      }

      if (inputMode == 'voice') {
        await _registerVoiceLearningSession(
          metadata: metadata,
          assistantMessage: finalAssistantMessage,
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'No se pudo contactar al tutor. Inténtalo nuevamente.';
        isSending = false;
      });
    }
  }

  Future<VoiceMessage?> generateAudioForAssistantMessage(
    VoiceMessage message, {
    bool autoPlay = false,
  }) async {
    if (message.role != 'assistant') return null;
    if (generatingAudioMessageIds.contains(message.messageId)) return null;
    if (voiceTtsService.hasAudio(message)) {
      if (autoPlay) {
        await playAssistantAudio(message);
      }
      return message;
    }

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

      if (!mounted) return null;

      setState(() {
        session = updatedSession;
        messages = _replaceMessage(messages, updatedMessage);
        generatingAudioMessageIds.remove(message.messageId);
      });

      if (!voiceTtsService.hasAudio(updatedMessage)) {
        _showSnackBar('No se pudo generar audio para esta respuesta.');
        return updatedMessage;
      }

      if (autoPlay) {
        await playAssistantAudio(updatedMessage);
      }

      return updatedMessage;
    } catch (_) {
      if (!mounted) return null;

      setState(() {
        generatingAudioMessageIds.remove(message.messageId);
      });
      _showSnackBar('No se pudo generar audio para esta respuesta.');
      return null;
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

  Future<void> startVoiceTurn() async {
    if (isSending || isProcessingVoiceInput) return;

    lastHandledVoiceText = '';
    await conversationService.startListening(
      onStateChanged: handleConversationState,
    );
  }

  Future<void> stopVoiceTurn() async {
    await conversationService.stopListening(
      onStateChanged: handleConversationState,
    );
  }

  Future<void> cancelVoiceTurn() async {
    await conversationService.cancelListening(
      onStateChanged: handleConversationState,
    );
    if (!mounted) return;

    setState(() {
      isProcessingVoiceInput = false;
      lastHandledVoiceText = '';
    });
  }

  void handleConversationState(VoiceConversationState state) {
    if (!mounted) return;

    setState(() {
      conversationState = state;
    });

    if (state.status == VoiceConversationService.denied) {
      _showSnackBar('Permiso de micrófono denegado.');
      return;
    }

    if (state.status == VoiceConversationService.error) {
      _showSnackBar(
        'Probemos otra vez. Revisa el micrófono e inténtalo de nuevo.',
      );
      return;
    }

    if (state.status != VoiceConversationService.processing) return;

    final finalText = state.finalText.trim();
    if (finalText.isEmpty) {
      _showSnackBar('No se detectó una pregunta clara.');
      return;
    }
    if (finalText == lastHandledVoiceText) return;

    lastHandledVoiceText = finalText;
    unawaited(sendVoiceTurn(state));
  }

  Future<void> sendVoiceTurn(VoiceConversationState state) async {
    if (!mounted) return;

    setState(() {
      isProcessingVoiceInput = true;
    });

    final turn = messages.where((message) => message.role == 'user').length + 1;

    await sendMessage(
      text: state.finalText,
      mode: 'general',
      inputMode: 'voice',
      autoGenerateAudio: true,
      metadata: {
        'speech_duration': state.durationSeconds,
        'mic_language': 'es_ES',
        'conversation_turn': turn,
      },
    );

    if (!mounted) return;

    setState(() {
      isProcessingVoiceInput = false;
      conversationState = VoiceConversationState.idleState.copyWith(
        finalText: state.finalText,
        durationSeconds: state.durationSeconds,
        startedAt: state.startedAt,
        endedAt: state.endedAt,
      );
    });
  }

  Future<void> _registerVoiceLearningSession({
    required Map<String, dynamic> metadata,
    required VoiceMessage assistantMessage,
  }) async {
    final audiobookId = voiceContext.audiobookId.trim();
    final chapterId = voiceContext.chapterId.trim();
    if (audiobookId.isEmpty || chapterId.isEmpty) return;

    final speechDuration = _intFrom(metadata['speech_duration']);
    final ttsDuration = voiceTtsService.durationSeconds(assistantMessage);
    final totalDuration = speechDuration + ttsDuration;

    try {
      await learningSessionService.saveSession(
        audiobookId: audiobookId,
        chapterId: chapterId,
        durationSeconds: totalDuration <= 0 ? 1 : totalDuration,
      );
    } catch (_) {
      // TODO Voice Intelligence 4.0: registrar analítica avanzada del tutor.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final payloadSuggestion =
        widget.payload['suggested_prompt']?.toString().trim() ?? '';
    final proactiveSuggestion = voiceContext.nextBestAction.trim().isNotEmpty
        ? voiceContext.nextBestAction.trim()
        : payloadSuggestion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor IA con Booky'),
      ),
      body: SafeArea(
        child: isLoading
            ? const StudyBookLoadingState(
                message: 'Booky está preparando tu contexto...',
              )
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
                                const BookyCard(
                                  message:
                                      'Pregúntame lo que quieras repasar. Estoy aquí para ayudarte.',
                                ),
                                const SizedBox(height: 16),
                                _ContextHeader(context: voiceContext),
                                const SizedBox(height: 16),
                                _ProactiveOpening(
                                  context: voiceContext,
                                  fallbackSuggestion: proactiveSuggestion,
                                ),
                                const SizedBox(height: 16),
                                _QuickActions(
                                  context: voiceContext,
                                  fallbackSuggestion: proactiveSuggestion,
                                  isBusy: isSending,
                                  onAction: sendMessage,
                                ),
                                const SizedBox(height: 16),
                                _VoiceInputPanel(
                                  state: conversationState,
                                  isBusy: isSending ||
                                      isProcessingVoiceInput ||
                                      isSpeaking,
                                  isThinking: isSending,
                                  isSpeaking: isSpeaking,
                                  onStart: startVoiceTurn,
                                  onStop: stopVoiceTurn,
                                  onCancel: cancelVoiceTurn,
                                ),
                                if (errorMessage.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _ErrorCard(
                                    message: errorMessage,
                                    onRetry: loadTutor,
                                  ),
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
        ],
      ),
    );
  }
}

class _ProactiveOpening extends StatelessWidget {
  final VoiceContext context;
  final String fallbackSuggestion;

  const _ProactiveOpening({
    required this.context,
    required this.fallbackSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final suggestion = this.context.nextBestAction.trim().isNotEmpty
        ? this.context.nextBestAction.trim()
        : fallbackSuggestion.trim().isNotEmpty
            ? fallbackSuggestion.trim()
            : 'Cuéntame qué quieres aprender y construiremos el siguiente paso.';
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppTheme.accent),
              SizedBox(width: 10),
              Text(
                'Podemos empezar por aquí',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            suggestion,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          if (this.context.actionReason.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              this.context.actionReason,
              style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
            ),
          ],
          if (this.context.studyPlanStatus.trim().isNotEmpty ||
              this.context.riskPriority.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (this.context.studyPlanStatus.trim().isNotEmpty)
                  Chip(label: Text(this.context.studyPlanStatus)),
                if (this.context.riskPriority.trim().isNotEmpty)
                  Chip(
                    label: Text('Prioridad: ${this.context.riskPriority}'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoiceContext context;
  final String fallbackSuggestion;
  final bool isBusy;
  final Future<void> Function({String? text, String mode}) onAction;

  const _QuickActions({
    required this.context,
    required this.fallbackSuggestion,
    required this.isBusy,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final nextAction = this.context.nextBestAction.trim().isNotEmpty
        ? this.context.nextBestAction.trim()
        : fallbackSuggestion.trim();
    final weakness = this.context.campusWeaknesses.isEmpty
        ? 'mi principal dificultad'
        : this.context.campusWeaknesses.first;
    final plan = this.context.priorityNextAction.trim().isNotEmpty
        ? this.context.priorityNextAction.trim()
        : this.context.smartStudyPlanSummary.trim();
    return SectionCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _ActionButton(
            label: 'Empecemos',
            mode: 'general',
            text: nextAction.isEmpty
                ? 'Ayúdame a elegir el mejor punto para empezar hoy.'
                : 'Ayúdame a comenzar con esta acción: $nextAction.',
            isBusy: isBusy,
            onAction: onAction,
          ),
          _ActionButton(
            label: 'Explícame',
            mode: 'explain',
            text: 'Explícame este tema paso a paso con un ejemplo claro.',
            isBusy: isBusy,
            onAction: onAction,
          ),
          _ActionButton(
            label: 'Hazme un quiz',
            mode: 'quiz',
            text: 'Hazme un quiz breve para comprobar lo que aprendí.',
            isBusy: isBusy,
            onAction: onAction,
          ),
          _ActionButton(
            label: 'Repasar debilidad',
            mode: 'review',
            text: 'Ayúdame a repasar esta debilidad: $weakness.',
            isBusy: isBusy,
            onAction: onAction,
          ),
          _ActionButton(
            label: 'Plan de hoy',
            mode: 'general',
            text: plan.isEmpty
                ? 'Ayúdame a organizar un plan breve para estudiar hoy.'
                : 'Ayúdame a ejecutar este plan de hoy: $plan.',
            isBusy: isBusy,
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
  final bool isBusy;
  final Future<void> Function({String? text, String mode}) onAction;

  const _ActionButton({
    required this.label,
    required this.mode,
    required this.text,
    required this.isBusy,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isBusy ? null : () => onAction(text: text, mode: mode),
      child: Text(label),
    );
  }
}

class _VoiceInputPanel extends StatelessWidget {
  final VoiceConversationState state;
  final bool isBusy;
  final bool isThinking;
  final bool isSpeaking;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const _VoiceInputPanel({
    required this.state,
    required this.isBusy,
    required this.isThinking,
    required this.isSpeaking,
    required this.onStart,
    required this.onStop,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isListening = state.status == VoiceConversationService.listening;
    final isProcessing = state.status == VoiceConversationService.processing;
    final isDenied = state.status == VoiceConversationService.denied;
    final isError = state.status == VoiceConversationService.error;
    final label = isSpeaking
        ? 'Hablando...'
        : isThinking
            ? 'Pensando...'
            : _statusLabel(state.status);
    final transcript = state.partialText.trim().isNotEmpty
        ? state.partialText
        : state.finalText.trim();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: (isListening ? AppTheme.danger : AppTheme.primary)
                      .withValues(alpha: isListening ? 0.22 : 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isListening ? AppTheme.danger : AppTheme.primary,
                    width: isListening ? 2 : 1,
                  ),
                ),
                child: Icon(
                  isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: isListening ? AppTheme.danger : AppTheme.accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDenied
                          ? 'Activa el permiso del micrófono para preguntar por voz.'
                          : isError
                              ? 'Probemos otra vez. Revisa el micrófono e inténtalo de nuevo.'
                              : isSpeaking
                                  ? 'Booky está reproduciendo su respuesta.'
                                  : isThinking
                                      ? 'Booky está preparando una respuesta.'
                                      : 'Habla, detén el micrófono y Booky te responderá con audio.',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (transcript.isNotEmpty) ...[
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.record_voice_over_rounded,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        transcript,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed:
                    isBusy || isListening || isProcessing ? null : onStart,
                icon: const Icon(Icons.mic_rounded),
                label: const Text('Preguntar por voz'),
              ),
              OutlinedButton.icon(
                onPressed: isListening ? onStop : null,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Detener'),
              ),
              OutlinedButton.icon(
                onPressed: isListening || isProcessing ? onCancel : null,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancelar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case VoiceConversationService.requestingPermission:
        return 'Solicitando permiso...';
      case VoiceConversationService.listening:
        return 'Escuchando...';
      case VoiceConversationService.processing:
        return 'Procesando...';
      case VoiceConversationService.denied:
        return 'Permiso denegado';
      case VoiceConversationService.error:
        return 'Probemos de nuevo';
      default:
        return 'Listo';
    }
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
        child: StudyBookEmptyState(
          title: 'Tu conversación está lista',
          message:
              'Elige una sugerencia o cuéntale a Booky qué quieres comprender mejor.',
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
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

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
          const SizedBox(width: 10),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
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

int _intFrom(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
