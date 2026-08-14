import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'auth_service.dart';

class AnalyticsService {
  static Future<Map<String, dynamic>> getSummary() async {
    final response = await http
        .get(
          Uri.parse('${ApiService.baseUrl}/analytics/summary'),
          headers: AuthService.authHeaders,
        )
        .timeout(ApiService.timeoutDuration);

    return ApiService.decodeResponse(response);
  }
}
