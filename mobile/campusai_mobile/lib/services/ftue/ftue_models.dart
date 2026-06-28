enum FtueUserPath { free, student, teacher, accessibility }

class FtueStep {
  final String id;
  final String title;
  final String description;
  final String actionLabel;
  final String routeName;
  final FtueUserPath userPath;
  final int estimatedMinutes;

  const FtueStep({
    required this.id,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.userPath,
    this.routeName = '',
    this.estimatedMinutes = 2,
  });
}

class FtueProgress {
  final FtueUserPath userPath;
  final List<String> completedStepIds;
  final bool dismissed;
  final DateTime startedAt;
  final DateTime updatedAt;

  const FtueProgress({
    required this.userPath,
    required this.completedStepIds,
    required this.dismissed,
    required this.startedAt,
    required this.updatedAt,
  });

  factory FtueProgress.initial(FtueUserPath userPath) {
    final now = DateTime.now();
    return FtueProgress(
      userPath: userPath,
      completedStepIds: const [],
      dismissed: false,
      startedAt: now,
      updatedAt: now,
    );
  }

  int completionPercentage(int totalSteps) {
    if (totalSteps <= 0) return 0;
    return ((completedStepIds.length / totalSteps) * 100).round().clamp(0, 100);
  }

  bool isComplete(int totalSteps) =>
      totalSteps > 0 && completedStepIds.length >= totalSteps;

  bool isStepComplete(String stepId) => completedStepIds.contains(stepId);

  FtueProgress copyWith({
    FtueUserPath? userPath,
    List<String>? completedStepIds,
    bool? dismissed,
    DateTime? startedAt,
    DateTime? updatedAt,
  }) {
    return FtueProgress(
      userPath: userPath ?? this.userPath,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      dismissed: dismissed ?? this.dismissed,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_path': userPath.name,
        'completed_step_ids': completedStepIds,
        'dismissed': dismissed,
        'started_at': startedAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory FtueProgress.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['completed_step_ids'];
    return FtueProgress(
      userPath: FtueUserPath.values.firstWhere(
        (item) => item.name == json['user_path']?.toString(),
        orElse: () => FtueUserPath.student,
      ),
      completedStepIds: rawSteps is List
          ? rawSteps
              .map((item) => item?.toString().trim() ?? '')
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList()
          : const [],
      dismissed: json['dismissed'] == true,
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
