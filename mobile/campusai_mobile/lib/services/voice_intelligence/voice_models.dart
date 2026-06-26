class VoiceMessage {
  final String messageId;
  final String role;
  final String content;
  final DateTime createdAt;
  final String source;
  final Map<String, dynamic> metadata;

  const VoiceMessage({
    this.messageId = '',
    this.role = 'user',
    this.content = '',
    required this.createdAt,
    this.source = 'text',
    this.metadata = const {},
  });

  factory VoiceMessage.empty() {
    return VoiceMessage(createdAt: DateTime.fromMillisecondsSinceEpoch(0));
  }

  factory VoiceMessage.fromJson(Map<String, dynamic> json) {
    return VoiceMessage(
      messageId: json['message_id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      source: json['source']?.toString() ?? 'text',
      metadata: _mapFrom(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'role': role,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'source': source,
      'metadata': metadata,
    };
  }
}

class VoiceSession {
  final String sessionId;
  final String audiobookId;
  final String chapterId;
  final String title;
  final DateTime startedAt;
  final DateTime updatedAt;
  final String status;
  final String mode;
  final List<VoiceMessage> messages;

  const VoiceSession({
    this.sessionId = '',
    this.audiobookId = '',
    this.chapterId = '',
    this.title = 'Tutor IA',
    required this.startedAt,
    required this.updatedAt,
    this.status = 'active',
    this.mode = 'general',
    this.messages = const [],
  });

  factory VoiceSession.empty() {
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    return VoiceSession(startedAt: now, updatedAt: now);
  }

  factory VoiceSession.fromJson(Map<String, dynamic> json) {
    return VoiceSession(
      sessionId: json['session_id']?.toString() ?? '',
      audiobookId: json['audiobook_id']?.toString() ?? '',
      chapterId: json['chapter_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Tutor IA',
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: json['status']?.toString() ?? 'active',
      mode: json['mode']?.toString() ?? 'general',
      messages: _mapList(json['messages'])
          .map((item) => VoiceMessage.fromJson(item))
          .toList(),
    );
  }

  VoiceSession copyWith({
    String? status,
    String? mode,
    DateTime? updatedAt,
    List<VoiceMessage>? messages,
  }) {
    return VoiceSession(
      sessionId: sessionId,
      audiobookId: audiobookId,
      chapterId: chapterId,
      title: title,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'audiobook_id': audiobookId,
      'chapter_id': chapterId,
      'title': title,
      'mode': mode,
      'status': status,
      'messages': messages.map((message) => message.toJson()).toList(),
      'started_at': startedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class VoiceContext {
  final String audiobookId;
  final String chapterId;
  final String audiobookTitle;
  final String chapterTitle;
  final String chapterSummary;
  final String transcript;
  final List<String> keyConcepts;
  final String learningPackSummary;
  final List<Map<String, dynamic>> flashcards;
  final List<Map<String, dynamic>> miniQuiz;
  final List<String> competencies;
  final int mastery;
  final List<String> recommendations;
  final String recommendedNextAction;
  final String academicRisk;
  final List<String> campusWeaknesses;
  final List<String> adaptivePlanSummary;

  const VoiceContext({
    this.audiobookId = '',
    this.chapterId = '',
    this.audiobookTitle = '',
    this.chapterTitle = '',
    this.chapterSummary = '',
    this.transcript = '',
    this.keyConcepts = const [],
    this.learningPackSummary = '',
    this.flashcards = const [],
    this.miniQuiz = const [],
    this.competencies = const [],
    this.mastery = 0,
    this.recommendations = const [],
    this.recommendedNextAction = '',
    this.academicRisk = 'Sin datos',
    this.campusWeaknesses = const [],
    this.adaptivePlanSummary = const [],
  });

  static const empty = VoiceContext();

  factory VoiceContext.fromJson(Map<String, dynamic> json) {
    return VoiceContext(
      audiobookId: json['audiobook_id']?.toString() ?? '',
      chapterId: json['chapter_id']?.toString() ?? '',
      audiobookTitle: json['audiobook_title']?.toString() ?? '',
      chapterTitle: json['chapter_title']?.toString() ?? '',
      chapterSummary: json['chapter_summary']?.toString() ?? '',
      transcript: json['transcript']?.toString() ?? '',
      keyConcepts: _stringList(json['key_concepts']),
      learningPackSummary: json['learning_pack_summary']?.toString() ?? '',
      flashcards: _mapList(json['flashcards']),
      miniQuiz: _mapList(json['mini_quiz']),
      competencies: _stringList(json['competencies']),
      mastery: _intFrom(json['mastery']),
      recommendations: _stringList(json['recommendations']),
      recommendedNextAction: json['recommended_next_action']?.toString() ?? '',
      academicRisk: json['academic_risk']?.toString() ?? 'Sin datos',
      campusWeaknesses: _stringList(json['campus_weaknesses']),
      adaptivePlanSummary: _stringList(json['adaptive_plan_summary']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audiobook_id': audiobookId,
      'chapter_id': chapterId,
      'audiobook_title': audiobookTitle,
      'chapter_title': chapterTitle,
      'chapter_summary': chapterSummary,
      'transcript': transcript,
      'key_concepts': keyConcepts,
      'learning_pack_summary': learningPackSummary,
      'flashcards': flashcards,
      'mini_quiz': miniQuiz,
      'competencies': competencies,
      'mastery': mastery,
      'recommendations': recommendations,
      'recommended_next_action': recommendedNextAction,
      'academic_risk': academicRisk,
      'campus_weaknesses': campusWeaknesses,
      'adaptive_plan_summary': adaptivePlanSummary,
    };
  }
}

class AiCoachResponse {
  final String text;
  final List<String> suggestions;
  final List<String> followUpQuestions;
  final String detectedIntent;
  final double confidence;
  final DateTime createdAt;

  const AiCoachResponse({
    this.text = '',
    this.suggestions = const [],
    this.followUpQuestions = const [],
    this.detectedIntent = 'general',
    this.confidence = 0,
    required this.createdAt,
  });

  factory AiCoachResponse.empty() {
    return AiCoachResponse(createdAt: DateTime.fromMillisecondsSinceEpoch(0));
  }

  factory AiCoachResponse.fromJson(Map<String, dynamic> json) {
    return AiCoachResponse(
      text: json['text']?.toString() ?? '',
      suggestions: _stringList(json['suggestions']),
      followUpQuestions: _stringList(json['follow_up_questions']),
      detectedIntent: json['detected_intent']?.toString() ?? 'general',
      confidence: _doubleFrom(json['confidence']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'suggestions': suggestions,
      'follow_up_questions': followUpQuestions,
      'detected_intent': detectedIntent,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

Map<String, dynamic> _mapFrom(dynamic raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(dynamic raw) {
  if (raw is! List) return <Map<String, dynamic>>[];
  return raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
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

double _doubleFrom(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
