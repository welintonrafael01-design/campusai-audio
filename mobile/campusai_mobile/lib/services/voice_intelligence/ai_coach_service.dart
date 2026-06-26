import '../api_service.dart';
import 'voice_memory_service.dart';
import 'voice_models.dart';

class AiCoachService {
  final VoiceMemoryService memoryService;

  const AiCoachService({
    this.memoryService = const VoiceMemoryService(),
  });

  Future<AiCoachResponse> askCoach({
    required String userMessage,
    required VoiceContext context,
    List<VoiceMessage> recentMessages = const [],
    String mode = 'general',
  }) async {
    final cleanMessage = userMessage.trim();
    if (cleanMessage.isEmpty) return AiCoachResponse.empty();

    final detectedIntent = _detectIntent(cleanMessage, mode);

    try {
      final response = await ApiService.askAiCoach(
        message: cleanMessage,
        mode: detectedIntent,
        context: _safeContext(context),
        recentMessages: memoryService.compactMessages(recentMessages),
      );
      final normalized = AiCoachResponse.fromJson({
        ...response,
        'detected_intent': response['detected_intent'] ?? detectedIntent,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (normalized.text.trim().isNotEmpty) return normalized;
    } catch (_) {
      // Backend opcional no disponible: usar fallback local.
    }

    return _localResponse(
      message: cleanMessage,
      context: context,
      intent: detectedIntent,
    );
  }

  AiCoachResponse _localResponse({
    required String message,
    required VoiceContext context,
    required String intent,
  }) {
    final title = context.chapterTitle.trim().isNotEmpty
        ? context.chapterTitle.trim()
        : 'este capítulo';
    final summary = context.chapterSummary.trim().isNotEmpty
        ? context.chapterSummary.trim()
        : context.learningPackSummary.trim();
    final concepts = context.keyConcepts.take(3).join(', ');

    final text = switch (intent) {
      'quiz' => _quizResponse(title, context),
      'review' => _reviewResponse(title, summary, concepts),
      'motivate' => _motivateResponse(title, context.mastery),
      'explain' => _explainResponse(title, summary, concepts),
      _ => _generalResponse(title, summary, concepts, context),
    };

    return AiCoachResponse(
      text: text,
      suggestions: const [
        'Explícame con un ejemplo',
        'Hazme una pregunta',
        'Resume lo más importante',
      ],
      followUpQuestions: [
        '¿Qué parte de $title quieres reforzar?',
        '¿Quieres practicar con flashcards o mini quiz?',
      ],
      detectedIntent: intent,
      confidence: 0.72,
      createdAt: DateTime.now(),
    );
  }

  String _detectIntent(String message, String mode) {
    final cleanMode = mode.trim().toLowerCase();
    if (cleanMode != 'general') return cleanMode;

    final lower = message.toLowerCase();
    if (lower.contains('pregunta') ||
        lower.contains('quiz') ||
        lower.contains('eval')) {
      return 'quiz';
    }
    if (lower.contains('resume') || lower.contains('repaso')) {
      return 'review';
    }
    if (lower.contains('motiva') || lower.contains('ánimo')) {
      return 'motivate';
    }
    if (lower.contains('explica') ||
        lower.contains('ejemplo') ||
        lower.contains('entiendo')) {
      return 'explain';
    }
    return 'general';
  }

  Map<String, dynamic> _safeContext(VoiceContext context) {
    return {
      ...context.toJson(),
      'audiobookTitle': context.audiobookTitle,
      'chapterTitle': context.chapterTitle,
      'chapterSummary': _limit(context.chapterSummary, 600),
      'learningPackSummary': _limit(context.learningPackSummary, 600),
      'keyConcepts': context.keyConcepts.take(6).toList(),
      'recommendedNextAction': _limit(context.recommendedNextAction, 160),
      'academicRisk': context.academicRisk,
      'campusWeaknesses': context.campusWeaknesses.take(4).toList(),
      'adaptivePlanSummary': context.adaptivePlanSummary.take(4).toList(),
      'masteryTrend': _limit(context.masteryTrend, 160),
      'riskTrend': _limit(context.riskTrend, 160),
      'latestRelevantChange': _limit(context.latestRelevantChange, 180),
      'longitudinalRecommendation':
          _limit(context.longitudinalRecommendation, 160),
      'adaptiveScheduleSummary': _limit(context.adaptiveScheduleSummary, 220),
      'smartStudyPlanSummary': _limit(context.smartStudyPlanSummary, 220),
      'enterpriseAnalyticsSummary':
          _limit(context.enterpriseAnalyticsSummary, 220),
      'bestStudyHours': context.bestStudyHours.take(3).toList(),
      'priorityNextAction': _limit(context.priorityNextAction, 160),
      'knowledgeMapSummary': _limit(context.knowledgeMapSummary, 220),
      'digitalTwinSummary': _limit(context.digitalTwinSummary, 220),
      'goalsSummary': _limit(context.goalsSummary, 220),
      'productivitySummary': _limit(context.productivitySummary, 220),
      'successPredictionSummary': _limit(context.successPredictionSummary, 220),
      'learningRoadmapSummary': _limit(context.learningRoadmapSummary, 220),
      'assistantMemorySummary': _limit(context.assistantMemorySummary, 220),
      'gamificationSummary': _limit(context.gamificationSummary, 160),
      'marketplaceSummary': _limit(context.marketplaceSummary, 160),
      'institutionSummary': _limit(context.institutionSummary, 160),
      'transcript': _limit(context.transcript, 1200),
      'flashcards': context.flashcards.take(5).toList(),
      'mini_quiz': context.miniQuiz.take(5).toList(),
      'recommendations': context.recommendations.take(5).toList(),
    };
  }

  String _generalResponse(
    String title,
    String summary,
    String concepts,
    VoiceContext context,
  ) {
    final parts = [
      'Puedo ayudarte con $title.',
      if (summary.isNotEmpty) 'Idea central: ${_limit(summary, 260)}',
      if (concepts.isNotEmpty) 'Conceptos clave: $concepts.',
      if (context.priorityNextAction.isNotEmpty)
        'Prioridad actual: ${context.priorityNextAction}.',
      'Puedes pedirme una explicación, un ejemplo, un repaso o preguntas de práctica.',
    ];
    return parts.join('\n\n');
  }

  String _explainResponse(String title, String summary, String concepts) {
    return [
      'Vamos paso a paso con $title.',
      if (summary.isNotEmpty)
        '1. Primero, recuerda esto: ${_limit(summary, 260)}',
      if (concepts.isNotEmpty) '2. Luego conecta estos conceptos: $concepts.',
      '3. Finalmente, intenta explicarlo con tus propias palabras y te ayudo a pulirlo.',
    ].join('\n\n');
  }

  String _quizResponse(String title, VoiceContext context) {
    if (context.miniQuiz.isNotEmpty) {
      final firstQuestion = context.miniQuiz.first;
      final question =
          firstQuestion['question']?.toString().trim() ?? '¿Qué aprendiste?';
      return 'Practiquemos $title.\n\nPregunta: $question';
    }

    final concept = context.keyConcepts.isNotEmpty
        ? context.keyConcepts.first
        : 'la idea principal';
    return 'Practiquemos $title.\n\nPregunta: ¿Cómo explicarías $concept con tus propias palabras?';
  }

  String _reviewResponse(String title, String summary, String concepts) {
    return [
      'Repaso rápido de $title:',
      if (summary.isNotEmpty) _limit(summary, 320),
      if (concepts.isNotEmpty) 'No pierdas de vista: $concepts.',
      'Después del repaso, responde el mini quiz para comprobar tu dominio.',
    ].join('\n\n');
  }

  String _motivateResponse(String title, int mastery) {
    final progress = mastery > 0 ? 'Tu dominio actual marca $mastery%.' : '';
    return [
      'Vas bien. $title se domina mejor con una repetición corta y activa.',
      if (progress.isNotEmpty) progress,
      'Escucha el capítulo otra vez, responde una pregunta y celebra el avance pequeño.',
    ].join('\n\n');
  }

  String _limit(String value, int maxLength) {
    final text = value.trim();
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
