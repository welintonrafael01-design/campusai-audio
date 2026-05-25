import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ApiService {
 static const String baseUrl = 'http://localhost:8000';

  static const String cloudBaseUrl = '';

  static const Duration timeoutDuration =
      Duration(seconds: 180);

  static const int maxPdfSizeMb = 25;


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
    final file = await pickPdfFile();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$baseUrl/documents/upload',
      ),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ),
    );

    return sendMultipartRequest(request);
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