import 'package:http/http.dart' as http;

import 'api_service.dart';

class DocumentService {
  static Future<Map<String, dynamic>> getDocumentInfo(
    String documentId,
  ) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/documents/info/$documentId',
    );

    final response = await http
        .get(uri)
        .timeout(ApiService.timeoutDuration);

    return ApiService.decodeResponse(response);
  }

  static String getPdfUrl(
    String documentId,
  ) {
    return '${ApiService.baseUrl}/documents/file/$documentId';
  }
}
