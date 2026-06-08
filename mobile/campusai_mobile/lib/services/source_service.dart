import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'auth_service.dart';

class SourceService {
  static Future<Map<String, dynamic>> getSourceChunk({
    required String documentId,
    required int chunkIndex,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/documents/source-chunk',
    ).replace(
      queryParameters: {
        'document_id': documentId,
        'chunk_index': chunkIndex.toString(),
      },
    );

    final response = await http
        .get(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(ApiService.timeoutDuration);

    return ApiService.decodeResponse(response);
  }
}
