import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'usage_limit_service.dart';
import 'auth_service.dart';

class ApiService {
 static const String baseUrl = 'http://localhost:8000';

  static const String cloudBaseUrl = '';

  static const Duration timeoutDuration =
      Duration(seconds: 180);

  static const int maxPdfSizeMb = 25;



  // =========================
  // SUBSCRIPTION
  // =========================

  static Future<Map<String, dynamic>> getSubscription() async {
    final uri = Uri.parse(
      '$baseUrl/billing/subscription/me',
    );

    final response = await http.get(
      uri,
      headers: AuthService.authHeaders,
    ).timeout(timeoutDuration);

    return decodeResponse(response);
  }

  // =========================
  // HEALTH
  // =========================

  static Future<Map<String, dynamic>>
      healthCheck() async {
    final uri = Uri.parse('$baseUrl/');

    final response = await http.get(uri);

    return decodeResponse(response);
  }

  // =========================
  // UPLOAD PDF
  // =========================

  static Future<Map<String, dynamic>>
      uploadPdf() async {
    const usageLimitService = UsageLimitService();

    if (!usageLimitService.canUploadPdfToday()) {
      throw Exception(
        usageLimitService.pdfUploadLimitMessage(),
      );
    }

    final file = await pickPdfFile();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$baseUrl/documents/upload',
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

  static Future<Map<String, dynamic>>
      chatWithDocumentId({
    required String documentId,
    required String question,
  }) async {
    final cleanDocumentId =
        requireValue(
      documentId,
      'No hay documento activo.',
    );

    final cleanQuestion =
        requireValue(
      question,
      'La pregunta no puede estar vacía.',
    );

    final uri = Uri.parse(
      '$baseUrl/documents/chat/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'question': cleanQuestion,
      },
    );

    final response = await http
        .post(uri)
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  



  // =========================
  // WORKSPACE CHAT
  // =========================

  static Future<Map<String, dynamic>>
      chatWithWorkspace({
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

    final uri = Uri.parse(
      '$baseUrl/documents/chat-workspace',
    ).replace(
      queryParameters: {
        'question': cleanQuestion,
      },
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
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

  static Stream<String>
      streamChatWithDocumentId({
    required String documentId,
    required String question,
  }) async* {

    final cleanDocumentId =
        requireValue(
      documentId,
      'No hay documento activo.',
    );

    final cleanQuestion =
        requireValue(
      question,
      'La pregunta no puede estar vacía.',
    );

    final uri = Uri.parse(
      '$baseUrl/documents/chat-stream/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'question': cleanQuestion,
      },
    );

    final request =
        http.Request('POST', uri);

    final streamedResponse =
        await request.send();

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw Exception(
        'Error iniciando streaming.',
      );
    }

    await for (final chunk
        in streamedResponse.stream.transform(
      utf8.decoder,
    )) {
      yield chunk;
    }
  }

// =========================
  // EXAM
  // =========================

  static Future<Map<String, dynamic>>
      generateExamByDocumentId({
    required String documentId,
    int numberOfQuestions = 10,
  }) async {
    final cleanDocumentId =
        requireValue(
      documentId,
      'No hay documento activo.',
    );

    final uri = Uri.parse(
      '$baseUrl/documents/exam/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'number_of_questions':
            numberOfQuestions.toString(),
      },
    );

    final response = await http
        .post(uri)
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  // =========================
  // FLASHCARDS
  // =========================

  static Future<Map<String, dynamic>>
      generateFlashcardsByDocumentId({
    required String documentId,
    int numberOfCards = 10,
  }) async {
    final cleanDocumentId =
        requireValue(
      documentId,
      'No hay documento activo.',
    );

    final uri = Uri.parse(
      '$baseUrl/documents/flashcards/$cleanDocumentId',
    ).replace(
      queryParameters: {
        'number_of_cards':
            numberOfCards.toString(),
      },
    );

    final response = await http
        .post(uri)
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }



  // =========================
  // GENERATE AUDIO
  // =========================

  static Future<Map<String, dynamic>>
      generateAudioFromText({
    required String text,
  }) async {
    final cleanText = requireValue(
      text,
      'No hay texto para generar audio.',
    );

    final uri = Uri.parse(
      '$baseUrl/documents/audio',
    ).replace(
      queryParameters: {
        'text': cleanText,
      },
    );

    final response = await http
        .post(uri)
        .timeout(timeoutDuration);

    return decodeResponse(response);
  }

  // =========================
  // AUDIO URL
  // =========================

  static String buildAudioUrl(
    String audioUrl,
  ) {
    final cleanAudioUrl =
        audioUrl.trim();

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

  static Stream<String>
      streamChatWithWorkspace({
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

    final uri = Uri.parse(
      '$baseUrl/documents/chat-workspace-stream',
    ).replace(
      queryParameters: {
        'question': cleanQuestion,
      },
    );

    final request = http.Request(
      'POST',
      uri,
    );

    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'document_ids': cleanDocumentIds,
      'history': history,
    });

    final streamedResponse = await request
        .send()
        .timeout(timeoutDuration);

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

  static Future<PlatformFile>
      pickPdfFile() async {
    final result =
        await FilePicker.platform.pickFiles(
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

    if (file.bytes == null ||
        file.bytes!.isEmpty) {
      throw Exception(
        'No se pudo leer el archivo.',
      );
    }

    if (!file.name
        .toLowerCase()
        .endsWith('.pdf')) {
      throw Exception(
        'Solo se permiten PDF.',
      );
    }

    final sizeMb =
        file.size / (1024 * 1024);

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

  static Future<Map<String, dynamic>>
      sendMultipartRequest(
    http.MultipartRequest request,
  ) async {
    final response = await request
        .send()
        .timeout(timeoutDuration);

    final body =
        await response.stream.bytesToString();

    return decodeBody(
      statusCode: response.statusCode,
      body: body,
    );
  }

  // =========================
  // DECODE RESPONSE
  // =========================

  static Map<String, dynamic>
      decodeResponse(
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

  static Map<String, dynamic>
      decodeBody({
    required int statusCode,
    required String body,
  }) {
    final decoded =
        tryDecodeJson(body);

    if (statusCode < 200 ||
        statusCode >= 300) {
      final detail =
          decoded['detail'] ?? body;

      throw Exception(
        'Error del servidor: $detail',
      );
    }

    return decoded;
  }

  // =========================
  // TRY JSON
  // =========================

  static Map<String, dynamic>
      tryDecodeJson(
    String body,
  ) {
    try {
      final decoded =
          jsonDecode(body);

      if (decoded
          is Map<String, dynamic>) {
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
    final cleanValue =
        value.trim();

    if (cleanValue.isEmpty) {
      throw Exception(message);
    }

    return cleanValue;
  }
}
