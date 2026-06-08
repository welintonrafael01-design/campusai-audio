import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'auth_service.dart';

class DocumentService {
  static String getPdfUrl(
    String documentId, {
    int? pageNumber,
  }) {
    final base = '${ApiService.baseUrl}/documents/file/$documentId';

    if (pageNumber == null) return base;

    return '$base#page=$pageNumber';
  }

  static Future<String> getSecurePdfUrl(
    String documentId, {
    int? pageNumber,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/documents/file-token/$documentId',
    );

    final response = await http.get(
      uri,
      headers: AuthService.authHeaders,
    );

    final data = ApiService.decodeResponse(response);

    final relativeUrl = data['file_url']?.toString();

    if (relativeUrl == null || relativeUrl.isEmpty) {
      throw Exception('No se pudo generar URL segura del PDF.');
    }

    final fullUrl = '${ApiService.baseUrl}$relativeUrl';

    if (pageNumber == null) return fullUrl;

    return '$fullUrl#page=$pageNumber';
  }
}
