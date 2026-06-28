import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/study_result.dart';
import '../study_result_service.dart';
import 'accessibility_models.dart';

/// Builds deterministic accessibility hints without invoking an AI engine.
class AccessibilityContentService {
  static const contentProfileType = 'accessibility_content_profile';
  static const contentProfileDocumentId =
      'accessibility_content_profile_current';

  const AccessibilityContentService();

  AccessibilityContentProfile buildProfile(
    AccessibilityPreferences preferences,
  ) {
    final supports = <String>[
      if (preferences.preferAudio) 'audio',
      if (preferences.largeText) 'large_text',
      if (preferences.highContrast) 'high_contrast',
      if (preferences.simpleLanguage) 'simple_language',
      if (preferences.reduceMotion) 'reduced_motion',
      if (preferences.stepByStepQuiz) 'step_by_step_quiz',
      if (preferences.simplifiedNavigation) 'simplified_navigation',
    ];
    return AccessibilityContentProfile(
      audioFirst: preferences.preferAudio,
      useSimpleLanguage: preferences.simpleLanguage,
      useShortSteps: preferences.stepByStepQuiz,
      useReducedMotion: preferences.reduceMotion,
      useSimplifiedNavigation: preferences.simplifiedNavigation,
      enabledSupports: supports,
      generatedAt: DateTime.now(),
    );
  }

  Future<AccessibilityContentProfile> buildAndSaveProfile(
    AccessibilityPreferences preferences,
  ) async {
    final profile = buildProfile(preferences);
    try {
      await StudyResultService.saveResult(
        StudyResult(
          documentId: contentProfileDocumentId,
          type: contentProfileType,
          content: jsonEncode(profile.toJson()),
          createdAt: profile.generatedAt.toIso8601String(),
        ),
      );
    } catch (error) {
      debugPrint('AccessibilityContentService.buildAndSaveProfile: $error');
    }
    return profile;
  }

  Future<AccessibilityContentProfile?> loadProfile() async {
    try {
      final result = await StudyResultService.getResult(
        documentId: contentProfileDocumentId,
        type: contentProfileType,
      );
      if (result == null) return null;
      final decoded = jsonDecode(result.content);
      if (decoded is Map) {
        return AccessibilityContentProfile.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (error) {
      debugPrint('AccessibilityContentService.loadProfile: $error');
    }
    return null;
  }

  List<String> learnerTips(AccessibilityPreferences preferences) => [
        if (preferences.preferAudio)
          'Escucha el contenido antes de comenzar la práctica.',
        if (preferences.simpleLanguage)
          'Pide a Booky una explicación con lenguaje simple.',
        if (preferences.stepByStepQuiz)
          'Responde una pregunta a la vez y revisa cada paso.',
        if (preferences.reduceMotion)
          'Usa transiciones reducidas para mantener el foco.',
      ];

  List<String> teacherAccessibilityActions() => const [
        'Generar versión accesible',
        'Crear resumen simple',
        'Crear actividad inclusiva',
        'Crear rúbrica con criterio de accesibilidad',
      ];
}
