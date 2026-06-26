import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger();
  void info(String message) {
    if (kDebugMode) debugPrint('[StudyBook] $message');
  }
}
