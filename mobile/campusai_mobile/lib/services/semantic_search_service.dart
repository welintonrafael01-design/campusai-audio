import 'package:http/http.dart' as http;

import '../models/semantic_search_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class SemanticSearchService {
  static Future<List<SemanticSearchModel>> search(
    String query,
  ) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      '${ApiService.baseUrl}/documents/semantic-search',
    ).replace(
      queryParameters: {
        'query': cleanQuery,
      },
    );

    final response = await http
        .get(
          uri,
          headers: AuthService.authHeaders,
        )
        .timeout(ApiService.timeoutDuration);

    final data = ApiService.decodeResponse(response);

    final rawResults = data['results'];

    if (rawResults is! List) {
      return [];
    }

    return rawResults
        .whereType<Map<String, dynamic>>()
        .map(SemanticSearchModel.fromMap)
        .toList();
  }
}
