/// Local preferences that describe how a learner wants to use StudyBook AI.
class AccessibilityPreferences {
  final bool largeText;
  final bool highContrast;
  final bool simpleLanguage;
  final bool reduceMotion;
  final bool preferAudio;
  final bool stepByStepQuiz;
  final bool simplifiedNavigation;
  final DateTime updatedAt;

  const AccessibilityPreferences({
    required this.largeText,
    required this.highContrast,
    required this.simpleLanguage,
    required this.reduceMotion,
    required this.preferAudio,
    required this.stepByStepQuiz,
    required this.simplifiedNavigation,
    required this.updatedAt,
  });

  factory AccessibilityPreferences.defaults() => AccessibilityPreferences(
        largeText: false,
        highContrast: false,
        simpleLanguage: false,
        reduceMotion: false,
        preferAudio: false,
        stepByStepQuiz: false,
        simplifiedNavigation: false,
        updatedAt: DateTime.now(),
      );

  int get enabledCount => [
        largeText,
        highContrast,
        simpleLanguage,
        reduceMotion,
        preferAudio,
        stepByStepQuiz,
        simplifiedNavigation,
      ].where((enabled) => enabled).length;

  AccessibilityPreferences copyWith({
    bool? largeText,
    bool? highContrast,
    bool? simpleLanguage,
    bool? reduceMotion,
    bool? preferAudio,
    bool? stepByStepQuiz,
    bool? simplifiedNavigation,
    DateTime? updatedAt,
  }) {
    return AccessibilityPreferences(
      largeText: largeText ?? this.largeText,
      highContrast: highContrast ?? this.highContrast,
      simpleLanguage: simpleLanguage ?? this.simpleLanguage,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      preferAudio: preferAudio ?? this.preferAudio,
      stepByStepQuiz: stepByStepQuiz ?? this.stepByStepQuiz,
      simplifiedNavigation: simplifiedNavigation ?? this.simplifiedNavigation,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'large_text': largeText,
        'high_contrast': highContrast,
        'simple_language': simpleLanguage,
        'reduce_motion': reduceMotion,
        'prefer_audio': preferAudio,
        'step_by_step_quiz': stepByStepQuiz,
        'simplified_navigation': simplifiedNavigation,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory AccessibilityPreferences.fromJson(Map<String, dynamic> json) {
    return AccessibilityPreferences(
      largeText: _boolFrom(json['large_text']),
      highContrast: _boolFrom(json['high_contrast']),
      simpleLanguage: _boolFrom(json['simple_language']),
      reduceMotion: _boolFrom(json['reduce_motion']),
      preferAudio: _boolFrom(json['prefer_audio']),
      stepByStepQuiz: _boolFrom(json['step_by_step_quiz']),
      simplifiedNavigation: _boolFrom(json['simplified_navigation']),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Derived content profile consumed by future Student and Teacher experiences.
class AccessibilityContentProfile {
  final bool audioFirst;
  final bool useSimpleLanguage;
  final bool useShortSteps;
  final bool useReducedMotion;
  final bool useSimplifiedNavigation;
  final List<String> enabledSupports;
  final DateTime generatedAt;

  const AccessibilityContentProfile({
    required this.audioFirst,
    required this.useSimpleLanguage,
    required this.useShortSteps,
    required this.useReducedMotion,
    required this.useSimplifiedNavigation,
    required this.enabledSupports,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'audio_first': audioFirst,
        'use_simple_language': useSimpleLanguage,
        'use_short_steps': useShortSteps,
        'use_reduced_motion': useReducedMotion,
        'use_simplified_navigation': useSimplifiedNavigation,
        'enabled_supports': enabledSupports,
        'generated_at': generatedAt.toIso8601String(),
      };

  factory AccessibilityContentProfile.fromJson(Map<String, dynamic> json) {
    final rawSupports = json['enabled_supports'];
    return AccessibilityContentProfile(
      audioFirst: _boolFrom(json['audio_first']),
      useSimpleLanguage: _boolFrom(json['use_simple_language']),
      useShortSteps: _boolFrom(json['use_short_steps']),
      useReducedMotion: _boolFrom(json['use_reduced_motion']),
      useSimplifiedNavigation: _boolFrom(json['use_simplified_navigation']),
      enabledSupports: rawSupports is List
          ? rawSupports
              .map((item) => item?.toString().trim() ?? '')
              .where((item) => item.isNotEmpty)
              .toList()
          : const [],
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

bool _boolFrom(dynamic value) {
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}
