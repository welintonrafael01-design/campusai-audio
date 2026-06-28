import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/study_result.dart';
import '../study_result_service.dart';
import 'accessibility_models.dart';

/// Local-first repository for the learner's accessibility preferences.
class AccessibilityPreferencesService {
  static const preferencesType = 'accessibility_preferences';
  static const preferencesDocumentId = 'accessibility_preferences_current';

  const AccessibilityPreferencesService();

  Future<AccessibilityPreferences> load() async {
    try {
      final result = await StudyResultService.getResult(
        documentId: preferencesDocumentId,
        type: preferencesType,
      );
      if (result == null) return AccessibilityPreferences.defaults();

      final decoded = jsonDecode(result.content);
      if (decoded is Map) {
        return AccessibilityPreferences.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (error) {
      debugPrint('AccessibilityPreferencesService.load: $error');
    }
    return AccessibilityPreferences.defaults();
  }

  Future<bool> save(AccessibilityPreferences preferences) async {
    try {
      final updated = preferences.copyWith(updatedAt: DateTime.now());
      await StudyResultService.saveResult(
        StudyResult(
          documentId: preferencesDocumentId,
          type: preferencesType,
          content: jsonEncode(updated.toJson()),
          createdAt: updated.updatedAt.toIso8601String(),
        ),
      );
      return true;
    } catch (error) {
      debugPrint('AccessibilityPreferencesService.save: $error');
      return false;
    }
  }

  Future<AccessibilityPreferences> reset() async {
    final defaults = AccessibilityPreferences.defaults();
    await save(defaults);
    return defaults;
  }
}
