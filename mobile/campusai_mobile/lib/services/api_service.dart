import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'usage_limit_service.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static const String cloudBaseUrl = '';

  static const Duration timeoutDuration = Duration(seconds: 180);

  static const int maxPdfSizeMb = 25;

  static const String localePreferenceKey = 'studybook_locale';

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
    AuthService.requireAccessToken;

    const usageLimitService = UsageLimitService();

    if (!usageLimitService.canUploadPdfToday()) {
      throw Exception(
        usageLimitService.pdfUploadLimitMessage(),
      );
    }

    final file = await pickPdfFile();

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
      AuthService.authHeaders,
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
          headers: AuthService.authHeaders,
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
            ...AuthService.authHeaders,
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
  // STREAM CHAT
  // =========================

  static Stream<String> streamChatWithDocumentId({
    required String documentId,
    required String question,
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
      AuthService.authHeaders,
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

  // =========================
  // FLASHCARDS
  // =========================

  static Future<Map<String, dynamic>> generateFlashcardsByDocumentId({
    required String documentId,
    int numberOfCards = 10,
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
          headers: AuthService.authHeaders,
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateWorkspaceFlashcards({
    required List<String> documentIds,
    int numberOfCards = 20,
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
            ...AuthService.authHeaders,
          },
          body: jsonEncode(cleanDocumentIds),
        )
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }


  static Future<Map<String, dynamic>> generateQuestionBankByDocumentId({
    required String documentId,
    int numberOfQuestions = 50,
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
        'rubric_type': rubricType,
        'criteria_count': criteriaCount.toString(),
        'performance_levels': performanceLevels.toString(),
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
      AuthService.authHeaders,
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
        'Error del servidor: $body',
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
      final detail = decoded['detail'] ?? body;

      throw Exception(
        'Error del servidor: $detail',
      );
    }

    return decoded;
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
