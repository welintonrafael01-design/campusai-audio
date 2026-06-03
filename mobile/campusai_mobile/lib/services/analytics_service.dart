import 'package:http/http.dart' as http;

import 'api_service.dart';

class AnalyticsService {
  static const adminApiKey =
      String.fromEnvironment('ADMIN_API_KEY');

  static Future<Map<String, dynamic>> getSummary() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/analytics/summary'),
      headers: {
        'X-Admin-Key': adminApiKey,
      },
    ).timeout(ApiService.timeoutDuration);

    return ApiService.decodeResponse(response);
  }
}
