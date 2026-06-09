import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'auth_service.dart';

class AudiobookService {
  const AudiobookService();

  Future<Map<String, dynamic>> generateAudiobookFromText({
    required String text,
    int maxChapters = 6,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('No hay texto suficiente para crear el audiolibro.');
    }

    final uri = Uri.parse(
      '${ApiService.baseUrl}/documents/audiobook',
    ).replace(
      queryParameters: {
        'text': cleanText,
        'max_chapters': maxChapters.toString(),
      },
    );

    final response = await http
        .post(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(ApiService.timeoutDuration);

    return ApiService.decodeResponse(response);
  }
}
