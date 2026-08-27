import 'package:flutter/foundation.dart';

class SafeDebugLog {
  const SafeDebugLog._();

  static String uploadCompletedMessage(Map<String, dynamic> response) {
    final documentId = response['document_id']?.toString().trim() ?? '';
    final safeId = documentId.length >= 8
        ? '${documentId.substring(0, 8)}...'
        : '[redacted]';

    return '[UPLOAD] success document=$safeId';
  }

  static void uploadCompleted(Map<String, dynamic> response) {
    if (kDebugMode) {
      debugPrint(uploadCompletedMessage(response));
    }
  }
}
