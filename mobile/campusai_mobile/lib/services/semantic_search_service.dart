import 'package:http/http.dart' as http;

import '../models/semantic_search_model.dart';
import 'api_service.dart';

class SemanticSearchService {
  static Future<List<SemanticSearchModel>> search(
    String query,
  ) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) return [];

    final uri = Uri.parse(
      '${ApiService.baseUrl}/documents/semantic-search',
    ).replace(
      queryParameters: {
        'query': cleanQuery,
      },
    );

    final response = await http
        .get(uri)
        .timeout(ApiService.timeoutDuration);

    final data = ApiService.decodeResponse(response);

    final results = data['results'];

    if (results is! List) return [];

    return results
        .map(
          (item) => SemanticSearchModel.fromMap(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
