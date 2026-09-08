import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_environment.dart';
import 'usage_limit_service.dart';
import 'auth_service.dart';

class ApiEntitlementException implements Exception {
  const ApiEntitlementException({
    required this.message,
    required this.code,
    this.requiredPlan,
    this.ctaLabel,
  });

  final String message;
  final String code;
  final String? requiredPlan;
  final String? ctaLabel;

  bool get hasUpgradeAction =>
      requiredPlan != null && ctaLabel != null && ctaLabel!.isNotEmpty;

  @override
  String toString() => message;
}

class ApiService {
  static final Random _operationRandom = Random.secure();

  static String get baseUrl => AppEnvironment.apiBaseUrl;

  static const String cloudBaseUrl = '';

  static const Duration timeoutDuration = Duration(seconds: 180);

  static const int maxPdfSizeMb = 25;

  static const String localePreferenceKey = 'studybook_locale';

  static String createOperationId() {
    final randomPart = List<int>.generate(
      16,
      (_) => _operationRandom.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return 'sb-${DateTime.now().toUtc().microsecondsSinceEpoch}-$randomPart';
  }

  static String resolveOperationId(String? operationId) {
    final cleanOperationId = operationId?.trim();
    return cleanOperationId == null || cleanOperationId.isEmpty
        ? createOperationId()
        : cleanOperationId;
  }

  static Map<String, String> operationHeaders([String? operationId]) {
    return {
      ...AuthService.authHeaders,
      'Idempotency-Key': resolveOperationId(operationId),
    };
  }

  static Future<String> getCurrentLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();

    final code = prefs.getString(localePreferenceKey) ?? 'es';

    final cleanCode = code.trim().toLowerCase();

    if ([
      'es',
      'en',
      'pt',
      'fr',
    ].contains(cleanCode)) {
      return cleanCode;
    }

    return 'es';
  }

  // =========================
  // USAGE SUMMARY
  // =========================

  static Future<Map<String, dynamic>> getUsageSummary() async {
    final uri = Uri.parse(
      '$baseUrl/billing/usage/me',
    );

    final response = await http
        .get(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  // =========================
  // SUBSCRIPTION
  // =========================

  static Future<Map<String, dynamic>> getSubscription() async {
    final uri = Uri.parse(
      '$baseUrl/billing/subscription/me',
    );

    final response = await http
        .get(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  // =========================
  // HEALTH
  // =========================

  static Future<Map<String, dynamic>> healthCheck() async {
    final uri = Uri.parse('$baseUrl/');

    final response = await http.get(uri);

    return decodeResponse(response);
  }

  // =========================
  // UPLOAD PDF
  // =========================

  static Future<Map<String, dynamic>> uploadPdf() async {
    final file = await pickPdfFile();

    return uploadPdfFile(file);
  }

  static Future<Map<String, dynamic>> uploadPdfFile(
    PlatformFile file, {
    String? operationId,
  }) async {
    AuthService.requireAccessToken;

    const usageLimitService = UsageLimitService();

    final language = await getCurrentLanguageCode();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$baseUrl/documents/upload',
      ).replace(
        queryParameters: {
          'language': language,
        },
      ),
    );

    request.headers.addAll(
      operationHeaders(operationId),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ),
    );

    final response = await sendMultipartRequest(request);

    usageLimitService.registerPdfUpload();

    return response;
  }

  // =========================
  // CHAT
  // =========================

  static Future<Map<String, dynamic>> chatWithDocumentId({
    required String documentId,
    required String question,
    String? operationId,
  }) async {
    final cleanDocumentId = requireValue(
      documentId,
      'No hay documento activo.',
    );

    final cleanQuestion = requireValue(
      question,
      'La pregunta no puede estar vacía.',
    );

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/chat/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'question': cleanQuestion,
        'language': language,
      },
    );

    final response = await http
        .post(
          uri,
          headers: operationHeaders(operationId),
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  // =========================
  // WORKSPACE CHAT
  // =========================

  static Future<Map<String, dynamic>> chatWithWorkspace({
    required List<String> documentIds,
    required String question,
    List<Map<String, String>> history = const [],
    String? operationId,
  }) async {
    final cleanDocumentIds = documentIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (cleanDocumentIds.isEmpty) {
      throw Exception(
        'El workspace no tiene documentos válidos.',
      );
    }

    final cleanQuestion = requireValue(
      question,
      'La pregunta no puede estar vacía.',
    );

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/chat-workspace',
    ).replace(
      queryParameters: {
        'question': cleanQuestion,
        'language': language,
      },
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            ...operationHeaders(operationId),
          },
          body: jsonEncode({
            'document_ids': cleanDocumentIds,
            'history': history,
          }),
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  // =========================
  // AI COACH
  // =========================

  static Future<Map<String, dynamic>> askAiCoach({
    required String message,
    String mode = 'general',
    Map<String, dynamic> context = const {},
    List<Map<String, dynamic>> recentMessages = const [],
  }) async {
    final cleanMessage = requireValue(
      message,
      'La pregunta no puede estar vacía.',
    );

    final response = await http
        .post(
          Uri.parse('$baseUrl/voice/coach'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'message': cleanMessage,
            'mode': mode.trim().isEmpty ? 'general' : mode.trim(),
            'context': context,
            'recent_messages': recentMessages,
          }),
        )
        .timeout(const Duration(seconds: 45));

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateVoiceTts({
    required String messageId,
    required String text,
    String voiceProfile = 'standard',
    String language = 'es',
  }) async {
    final cleanText = requireValue(
      text,
      'No hay texto válido para generar audio.',
    );

    final response = await http
        .post(
          Uri.parse('$baseUrl/voice/tts'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'message_id': messageId.trim(),
            'text': cleanText,
            'voice_profile':
                voiceProfile.trim().isEmpty ? 'standard' : voiceProfile.trim(),
            'language': language.trim().isEmpty ? 'es' : language.trim(),
          }),
        )
        .timeout(const Duration(seconds: 60));

    return decodeResponse(response);
  }

  // =========================
  // STREAM CHAT
  // =========================

  static Stream<String> streamChatWithDocumentId({
    required String documentId,
    required String question,
    String? operationId,
  }) async* {
    final cleanDocumentId = requireValue(
      documentId,
      'No hay documento activo.',
    );

    final cleanQuestion = requireValue(
      question,
      'La pregunta no puede estar vacía.',
    );

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/chat-stream/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'question': cleanQuestion,
        'language': language,
      },
    );

    final request = http.Request('POST', uri);

    request.headers.addAll(
      operationHeaders(operationId),
    );

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw Exception(
        'Error iniciando streaming.',
      );
    }

    await for (final chunk in streamedResponse.stream.transform(
      utf8.decoder,
    )) {
      yield chunk;
    }
  }

// =========================
  // EXAM
  // =========================

  static Future<Map<String, dynamic>> generateExamByDocumentId({
    required String documentId,
    int numberOfQuestions = 10,
    String examType = 'Selección múltiple',
    String difficulty = 'Intermedio',
    int totalPoints = 100,
    String examTopic = '',
    String examObjective = '',
    String generationType = 'exam',
    String? operationId,
  }) async {
    final cleanDocumentId = requireValue(
      documentId,
      'No hay documento activo.',
    );

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/exam/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'number_of_questions': numberOfQuestions.toString(),
        'exam_type': examType,
        'difficulty': difficulty,
        'total_points': totalPoints.toString(),
        'exam_topic': examTopic,
        'exam_objective': examObjective,
        'generation_type': generationType == 'quiz' ? 'quiz' : 'exam',
        'language': language,
      },
    );

    final response = await http
        .post(
          uri,
          headers: operationHeaders(operationId),
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  // =========================
  // FLASHCARDS
  // =========================

  static Future<Map<String, dynamic>> generateFlashcardsByDocumentId({
    required String documentId,
    int numberOfCards = 10,
    String? operationId,
  }) async {
    final cleanDocumentId = requireValue(
      documentId,
      'No hay documento activo.',
    );

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/flashcards/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'number_of_cards': numberOfCards.toString(),
        'language': language,
      },
    );

    final response = await http
        .post(
          uri,
          headers: operationHeaders(operationId),
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateWorkspaceFlashcards({
    required List<String> documentIds,
    int numberOfCards = 20,
    String? operationId,
  }) async {
    final cleanDocumentIds = documentIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (cleanDocumentIds.isEmpty) {
      throw Exception('El workspace no tiene documentos válidos.');
    }

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/workspace-flashcards',
    ).replace(
      queryParameters: {
        'number': numberOfCards.toString(),
        'language': language,
      },
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            ...operationHeaders(operationId),
          },
          body: jsonEncode(cleanDocumentIds),
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateQuestionBankByDocumentId({
    required String documentId,
    int numberOfQuestions = 50,
    String programTopic = '',
    String learningObjective = '',
    String competency = '',
    String bloomLevel = '',
  }) async {
    final cleanDocumentId = requireValue(
      documentId,
      'No hay documento activo.',
    );

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/question-bank/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'number_of_questions': numberOfQuestions.toString(),
        'language': language,
        if (programTopic.trim().isNotEmpty)
          'program_topic': programTopic.trim(),
        if (learningObjective.trim().isNotEmpty)
          'learning_objective': learningObjective.trim(),
        if (competency.trim().isNotEmpty) 'competency': competency.trim(),
        if (bloomLevel.trim().isNotEmpty) 'bloom_level': bloomLevel.trim(),
      },
    );

    final response = await http
        .post(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateWorkspaceQuestionBank({
    required List<String> documentIds,
    int numberOfQuestions = 50,
  }) async {
    final cleanDocumentIds = documentIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (cleanDocumentIds.isEmpty) {
      throw Exception('El workspace no tiene documentos válidos.');
    }

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/workspace-question-bank',
    ).replace(
      queryParameters: {
        'number': numberOfQuestions.toString(),
        'language': language,
      },
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode(cleanDocumentIds),
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateWorkspaceExam({
    required List<String> documentIds,
    int numberOfQuestions = 20,
  }) async {
    final cleanDocumentIds = documentIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (cleanDocumentIds.isEmpty) {
      throw Exception('El workspace no tiene documentos válidos.');
    }

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/workspace-exam',
    ).replace(
      queryParameters: {
        'number': numberOfQuestions.toString(),
        'language': language,
      },
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode(cleanDocumentIds),
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> importGradesExcel() async {
    final file = await pickExcelFile();
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('No se pudo leer el archivo Excel seleccionado.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/documents/import-grades-excel'),
    );

    request.headers.addAll(AuthService.authHeaders);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ),
    );

    return sendMultipartRequest(request);
  }

  static Future<Map<String, dynamic>> importGradesPdf() async {
    final file = await pickPdfFile();
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('No se pudo leer el archivo PDF seleccionado.');
    }

    final language = await getCurrentLanguageCode();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/documents/import-grades-pdf').replace(
        queryParameters: {
          'language': language,
        },
      ),
    );

    request.headers.addAll(AuthService.authHeaders);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ),
    );

    return sendMultipartRequest(request);
  }

  static Future<Map<String, dynamic>> importStudentsPdf() async {
    final file = await pickPdfFile();
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('No se pudo leer el archivo PDF seleccionado.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/documents/import-students-pdf'),
    );

    request.headers.addAll(AuthService.authHeaders);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateTeachingPlanByDocumentId({
    required String documentId,
    int weeks = 4,
  }) async {
    final cleanDocumentId = requireValue(
      documentId,
      'No hay documento activo.',
    );

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/teaching-plan/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'weeks': weeks.toString(),
        'language': language,
      },
    );

    final response = await http
        .post(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateRubricByDocumentId({
    required String documentId,
    int totalPoints = 100,
    String rubricType = 'Analítica',
    int criteriaCount = 5,
    int performanceLevels = 4,
    String programTopic = '',
    String learningObjective = '',
    String competency = '',
  }) async {
    final cleanDocumentId = requireValue(
      documentId,
      'No hay documento activo.',
    );

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/rubric/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'total_points': totalPoints.toString(),
        'rubric_type': rubricType,
        'criteria_count': criteriaCount.toString(),
        'performance_levels': performanceLevels.toString(),
        'language': language,
        if (programTopic.trim().isNotEmpty)
          'program_topic': programTopic.trim(),
        if (learningObjective.trim().isNotEmpty)
          'learning_objective': learningObjective.trim(),
        if (competency.trim().isNotEmpty) 'competency': competency.trim(),
      },
    );

    final response = await http
        .post(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateStudyGuideByDocumentId({
    required String documentId,
    String programTopic = '',
    String learningObjective = '',
    String competency = '',
    String guideType = 'student',
    bool includeSummary = true,
    bool includeKeyConcepts = true,
    bool includePracticeActivities = true,
    bool includeSelfAssessment = true,
  }) async {
    final cleanDocumentId = requireValue(
      documentId,
      'No hay documento activo.',
    );

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/study-guide/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'language': language,
        'guide_type': guideType,
        'include_summary': includeSummary.toString(),
        'include_key_concepts': includeKeyConcepts.toString(),
        'include_practice_activities': includePracticeActivities.toString(),
        'include_self_assessment': includeSelfAssessment.toString(),
        if (programTopic.trim().isNotEmpty)
          'program_topic': programTopic.trim(),
        if (learningObjective.trim().isNotEmpty)
          'learning_objective': learningObjective.trim(),
        if (competency.trim().isNotEmpty) 'competency': competency.trim(),
      },
    );

    final response = await http
        .post(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateTeachingResourcesByDocumentId({
    required String documentId,
    String programTopic = '',
    String learningObjective = '',
    String competency = '',
    bool includePresentationOutline = true,
    bool includeClassActivities = true,
    bool includeCollaborativeActivities = true,
    bool includeDiscussionQuestions = true,
    bool includeProblemBasedLearning = true,
    bool includeGamificationIdeas = true,
    bool includeHomework = true,
    bool includeAccessibilityAdaptations = true,
    bool includeComplementaryReadings = true,
    bool includeMultimediaSuggestions = true,
    bool includeWebResources = true,
    bool includeAiPromptsForStudents = true,
  }) async {
    final cleanDocumentId = requireValue(
      documentId,
      'No hay documento activo.',
    );

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/teaching-resources/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'language': language,
        'include_presentation_outline': includePresentationOutline.toString(),
        'include_class_activities': includeClassActivities.toString(),
        'include_collaborative_activities':
            includeCollaborativeActivities.toString(),
        'include_discussion_questions': includeDiscussionQuestions.toString(),
        'include_problem_based_learning':
            includeProblemBasedLearning.toString(),
        'include_gamification_ideas': includeGamificationIdeas.toString(),
        'include_homework': includeHomework.toString(),
        'include_accessibility_adaptations':
            includeAccessibilityAdaptations.toString(),
        'include_complementary_readings':
            includeComplementaryReadings.toString(),
        'include_multimedia_suggestions':
            includeMultimediaSuggestions.toString(),
        'include_web_resources': includeWebResources.toString(),
        'include_ai_prompts_for_students':
            includeAiPromptsForStudents.toString(),
        if (programTopic.trim().isNotEmpty)
          'program_topic': programTopic.trim(),
        if (learningObjective.trim().isNotEmpty)
          'learning_objective': learningObjective.trim(),
        if (competency.trim().isNotEmpty) 'competency': competency.trim(),
      },
    );

    final response = await http
        .post(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> analyzeAssessmentForUnit({
    required Map<String, dynamic> academicMetadata,
    required List<String> objectives,
    required List<String> competencies,
    required List<Map<String, dynamic>> questionBank,
    required List<Map<String, dynamic>> exam,
    required Map<String, dynamic> rubric,
    required Map<String, dynamic> studyGuide,
  }) async {
    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/analyze-assessment',
    ).replace(
      queryParameters: {
        'language': language,
      },
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'academic_metadata': academicMetadata,
            'objectives': objectives,
            'competencies': competencies,
            'question_bank': questionBank,
            'exam': exam,
            'rubric': rubric,
            'study_guide': studyGuide,
          }),
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  // =========================
  // GENERATE AUDIO
  // =========================

  static Future<Map<String, dynamic>> generateAudioFromText({
    required String text,
  }) async {
    final cleanText = requireValue(
      text,
      'No hay texto para generar audio.',
    );

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/audio',
    ).replace(
      queryParameters: {
        'text': cleanText,
        'language': language,
      },
    );

    final response = await http
        .post(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateAudioBookFromText({
    required String title,
    required String text,
    String sourceMode = 'solo',
    String sourceType = 'text',
    String sourceDocumentId = '',
    String courseId = '',
    String courseName = '',
    String unitId = '',
    String unitTopic = '',
    String language = 'es',
    String voiceProfile = 'standard',
  }) async {
    final cleanText = requireValue(
      text,
      'No hay texto para generar Audio Libro.',
    );

    final cleanLanguage =
        language.trim().isEmpty ? await getCurrentLanguageCode() : language;

    final response = await http
        .post(
          Uri.parse('$baseUrl/audiobook/generate'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'title': title,
            'text': cleanText,
            'source_mode': sourceMode,
            'source_type': sourceType,
            'source_document_id': sourceDocumentId,
            'course_id': courseId,
            'course_name': courseName,
            'unit_id': unitId,
            'unit_topic': unitTopic,
            'language': cleanLanguage,
            'voice_profile': voiceProfile,
          }),
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateAudioForAudioBookChapter({
    required String audiobookId,
    required String chapterId,
    required String chapterTitle,
    required String script,
    String voiceProfile = 'standard',
    String language = 'es',
  }) async {
    final cleanScript = requireValue(
      script,
      'No hay guion para generar audio.',
    );
    final cleanLanguage =
        language.trim().isEmpty ? await getCurrentLanguageCode() : language;

    final response = await http
        .post(
          Uri.parse('$baseUrl/audiobook/generate-chapter-audio'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'audiobook_id': audiobookId,
            'chapter_id': chapterId,
            'chapter_title': chapterTitle,
            'script': cleanScript,
            'voice_profile': voiceProfile,
            'language': cleanLanguage,
          }),
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateLearningPackForAudioBookChapter({
    required String audiobookId,
    required String chapterId,
    required String chapterTitle,
    required String summary,
    required String script,
    required String transcript,
    List<String> keyConcepts = const [],
    String language = 'es',
  }) async {
    final cleanLanguage =
        language.trim().isEmpty ? await getCurrentLanguageCode() : language;

    final response = await http
        .post(
          Uri.parse('$baseUrl/audiobook/generate-learning-pack'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'audiobook_id': audiobookId,
            'chapter_id': chapterId,
            'chapter_title': chapterTitle,
            'summary': summary,
            'script': script,
            'transcript': transcript,
            'key_concepts': keyConcepts,
            'language': cleanLanguage,
          }),
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  // =========================
  // AUDIO URL
  // =========================

  static String buildAudioUrl(
    String audioUrl,
  ) {
    final cleanAudioUrl = audioUrl.trim();

    if (cleanAudioUrl.isEmpty) {
      return '';
    }

    if (cleanAudioUrl.startsWith(
          'http://',
        ) ||
        cleanAudioUrl.startsWith(
          'https://',
        )) {
      return cleanAudioUrl;
    }

    if (cleanAudioUrl.startsWith('/')) {
      return '$baseUrl$cleanAudioUrl';
    }

    return '$baseUrl/$cleanAudioUrl';
  }

  // =========================
  // REAL STREAM CHAT
  // =========================

  static Stream<String> streamChatWithWorkspace({
    required List<String> documentIds,
    required String question,
    List<Map<String, String>> history = const [],
    String? operationId,
  }) async* {
    final cleanDocumentIds = documentIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (cleanDocumentIds.isEmpty) {
      throw Exception(
        'El workspace no tiene documentos válidos.',
      );
    }

    final cleanQuestion = requireValue(
      question,
      'La pregunta no puede estar vacía.',
    );

    final language = await getCurrentLanguageCode();

    final uri = Uri.parse(
      '$baseUrl/documents/chat-workspace-stream',
    ).replace(
      queryParameters: {
        'question': cleanQuestion,
        'language': language,
      },
    );

    final request = http.Request(
      'POST',
      uri,
    );

    request.headers.addAll(
      operationHeaders(operationId),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'document_ids': cleanDocumentIds,
      'history': history,
    });

    final streamedResponse = await request.send().timeout(timeoutDuration);

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      final body = await streamedResponse.stream.bytesToString();

      throw Exception(
        safeErrorMessage(
          statusCode: streamedResponse.statusCode,
          body: body,
        ),
      );
    }

    await for (final chunk in streamedResponse.stream.transform(
      utf8.decoder,
    )) {
      yield chunk;
    }
  }

  // =========================
  // PICK PDF
  // =========================

  static Future<PlatformFile> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xlsm'],
      withData: true,
    );

    if (result == null) {
      throw Exception('No se seleccionó archivo.');
    }

    final file = result.files.first;

    if (file.bytes == null || file.bytes!.isEmpty) {
      throw Exception('No se pudo leer el archivo.');
    }

    final lowerName = file.name.toLowerCase();

    if (!lowerName.endsWith('.xlsx') && !lowerName.endsWith('.xlsm')) {
      throw Exception('Solo se permiten archivos Excel .xlsx o .xlsm.');
    }

    return file;
  }

  static Future<PlatformFile> pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null) {
      throw Exception(
        'No se seleccionó archivo.',
      );
    }

    final file = result.files.first;

    if (file.bytes == null || file.bytes!.isEmpty) {
      throw Exception(
        'No se pudo leer el archivo.',
      );
    }

    if (!file.name.toLowerCase().endsWith('.pdf')) {
      throw Exception(
        'Solo se permiten PDF.',
      );
    }

    final sizeMb = file.size / (1024 * 1024);

    if (sizeMb > maxPdfSizeMb) {
      throw Exception(
        'El PDF supera 25 MB.',
      );
    }

    return file;
  }

  // =========================
  // MULTIPART
  // =========================

  static Future<Map<String, dynamic>> sendMultipartRequest(
    http.MultipartRequest request,
  ) async {
    final response = await request.send().timeout(timeoutDuration);

    final body = await response.stream.bytesToString();

    return decodeBody(
      statusCode: response.statusCode,
      body: body,
    );
  }

  // =========================
  // DECODE RESPONSE
  // =========================

  static Map<String, dynamic> decodeResponse(
    http.Response response,
  ) {
    return decodeBody(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  // =========================
  // DECODE BODY
  // =========================

  static Map<String, dynamic> decodeBody({
    required int statusCode,
    required String body,
  }) {
    final decoded = tryDecodeJson(body);

    if (statusCode < 200 || statusCode >= 300) {
      final detail = decoded['detail'];
      if (detail is Map) {
        final message = detail['message']?.toString().trim();
        final code = detail['code']?.toString().trim();
        final cta = detail['cta'];
        if (message != null &&
            message.isNotEmpty &&
            code != null &&
            code.isNotEmpty) {
          throw ApiEntitlementException(
            message: message,
            code: code,
            requiredPlan: detail['required_plan']?.toString(),
            ctaLabel: cta is Map ? cta['label']?.toString() : null,
          );
        }
      }
      throw Exception(
        safeErrorMessage(
          statusCode: statusCode,
          body: body,
          decoded: decoded,
        ),
      );
    }

    return decoded;
  }

  static String safeErrorMessage({
    required int statusCode,
    required String body,
    Map<String, dynamic>? decoded,
  }) {
    if (statusCode >= 500) {
      return 'El servidor no pudo completar la solicitud. Inténtalo nuevamente.';
    }

    Map<String, dynamic> data = decoded ?? const {};
    if (data.isEmpty) {
      try {
        data = tryDecodeJson(body);
      } catch (_) {
        return 'No se pudo completar la solicitud.';
      }
    }

    final detail = data['detail'];
    if (detail is Map) {
      final message = detail['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        final cleanMessage =
            message.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
        return cleanMessage.length <= 500
            ? cleanMessage
            : '${cleanMessage.substring(0, 497)}...';
      }
    }
    if (detail is String && detail.trim().isNotEmpty) {
      final cleanDetail = detail.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
      return cleanDetail.length <= 500
          ? cleanDetail
          : '${cleanDetail.substring(0, 497)}...';
    }

    return 'No se pudo completar la solicitud.';
  }

  // =========================
  // TRY JSON
  // =========================

  static Map<String, dynamic> tryDecodeJson(
    String body,
  ) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'data': decoded,
      };
    } catch (_) {
      throw Exception(
        'Respuesta inválida del servidor.',
      );
    }
  }

  // =========================
  // REQUIRE VALUE
  // =========================

  static String requireValue(
    String value,
    String message,
  ) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) {
      throw Exception(message);
    }

    return cleanValue;
  }
}
