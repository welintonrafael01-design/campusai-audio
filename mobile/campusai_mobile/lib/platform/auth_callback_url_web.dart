import 'package:web/web.dart' as web;

void clearAuthCallbackParameters(Uri uri) {
  if (!uri.queryParameters.containsKey('code') &&
      !uri.queryParameters.containsKey('error')) {
    return;
  }

  final sanitized = uri.replace(queryParameters: const {});
  web.window.history.replaceState(null, '', sanitized.toString());
}
