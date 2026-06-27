enum LaunchCheckStatus { ready, pending, blocked }

enum FeedbackCategory {
  bug,
  ux,
  performance,
  content,
  voice,
  dashboard,
  audiobook,
  teacher,
  marketplace,
  institution,
}

enum FeedbackPriority { low, normal, high, critical }

enum FeedbackStatus { open, reviewed, resolved }

class LaunchReadinessCheck {
  final String id;
  final String title;
  final String area;
  final LaunchCheckStatus status;
  final String evidence;
  final bool requiredForClosedBeta;

  const LaunchReadinessCheck({
    required this.id,
    required this.title,
    required this.area,
    required this.status,
    this.evidence = '',
    this.requiredForClosedBeta = true,
  });

  factory LaunchReadinessCheck.fromJson(Map<String, dynamic> json) =>
      LaunchReadinessCheck(
        id: _text(json['id']),
        title: _text(json['title']),
        area: _text(json['area']),
        status: _enumValue(
          LaunchCheckStatus.values,
          json['status'],
          LaunchCheckStatus.pending,
        ),
        evidence: _text(json['evidence']),
        requiredForClosedBeta: json['required_for_closed_beta'] != false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'area': area,
        'status': status.name,
        'evidence': evidence,
        'required_for_closed_beta': requiredForClosedBeta,
      };
}

class LaunchReadinessReport {
  final DateTime generatedAt;
  final int score;
  final bool readyForClosedBeta;
  final List<LaunchReadinessCheck> checks;
  final List<String> blockers;
  final List<String> nextSteps;
  final int feedbackCount;
  final int onboardingProgress;

  const LaunchReadinessReport({
    required this.generatedAt,
    this.score = 0,
    this.readyForClosedBeta = false,
    this.checks = const [],
    this.blockers = const [],
    this.nextSteps = const [],
    this.feedbackCount = 0,
    this.onboardingProgress = 0,
  });

  factory LaunchReadinessReport.empty() => LaunchReadinessReport(
        generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  factory LaunchReadinessReport.fromJson(Map<String, dynamic> json) =>
      LaunchReadinessReport(
        generatedAt: _date(json['generated_at']),
        score: _int(json['score']).clamp(0, 100),
        readyForClosedBeta: json['ready_for_closed_beta'] == true,
        checks:
            _maps(json['checks']).map(LaunchReadinessCheck.fromJson).toList(),
        blockers: _strings(json['blockers']),
        nextSteps: _strings(json['next_steps']),
        feedbackCount: _int(json['feedback_count']),
        onboardingProgress: _int(json['onboarding_progress']).clamp(0, 100),
      );

  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'score': score,
        'ready_for_closed_beta': readyForClosedBeta,
        'checks': checks.map((item) => item.toJson()).toList(),
        'blockers': blockers,
        'next_steps': nextSteps,
        'feedback_count': feedbackCount,
        'onboarding_progress': onboardingProgress,
      };
}

class BetaFeedback {
  final String id;
  final FeedbackCategory category;
  final FeedbackPriority priority;
  final FeedbackStatus status;
  final String message;
  final String source;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const BetaFeedback({
    required this.id,
    required this.category,
    required this.priority,
    required this.status,
    required this.message,
    required this.source,
    required this.createdAt,
    this.reviewedAt,
  });

  factory BetaFeedback.fromJson(Map<String, dynamic> json) => BetaFeedback(
        id: _text(json['id']),
        category: _enumValue(
          FeedbackCategory.values,
          json['category'],
          FeedbackCategory.ux,
        ),
        priority: _enumValue(
          FeedbackPriority.values,
          json['priority'],
          FeedbackPriority.normal,
        ),
        status: _enumValue(
          FeedbackStatus.values,
          json['status'],
          FeedbackStatus.open,
        ),
        message: _text(json['message']),
        source: _text(json['source'], 'app'),
        createdAt: _date(json['created_at']),
        reviewedAt: DateTime.tryParse(_text(json['reviewed_at'])),
      );

  BetaFeedback copyWith({FeedbackStatus? status, DateTime? reviewedAt}) =>
      BetaFeedback(
        id: id,
        category: category,
        priority: priority,
        status: status ?? this.status,
        message: message,
        source: source,
        createdAt: createdAt,
        reviewedAt: reviewedAt ?? this.reviewedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'priority': priority.name,
        'status': status.name,
        'message': message,
        'source': source,
        'created_at': createdAt.toIso8601String(),
        'reviewed_at': reviewedAt?.toIso8601String() ?? '',
      };
}

class FeedbackSummary {
  final int total;
  final int open;
  final int reviewed;
  final int critical;
  final Map<String, int> byCategory;

  const FeedbackSummary({
    this.total = 0,
    this.open = 0,
    this.reviewed = 0,
    this.critical = 0,
    this.byCategory = const {},
  });
}

class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final String role;
  final String routeName;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.role,
    this.routeName = '',
  });
}

class OnboardingProgress {
  final String role;
  final List<String> completedStepIds;
  final int totalSteps;
  final bool skipped;
  final DateTime updatedAt;

  const OnboardingProgress({
    required this.role,
    required this.completedStepIds,
    required this.totalSteps,
    required this.updatedAt,
    this.skipped = false,
  });

  factory OnboardingProgress.empty({int totalSteps = 0}) => OnboardingProgress(
        role: 'student',
        completedStepIds: const [],
        totalSteps: totalSteps,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) =>
      OnboardingProgress(
        role: _text(json['role'], 'student'),
        completedStepIds: _strings(json['completed_step_ids']),
        totalSteps: _int(json['total_steps']),
        skipped: json['skipped'] == true,
        updatedAt: _date(json['updated_at']),
      );

  bool get completed =>
      skipped || (totalSteps > 0 && completedStepIds.length >= totalSteps);

  int get percentage => totalSteps <= 0
      ? 0
      : ((completedStepIds.length / totalSteps) * 100).round().clamp(0, 100);

  Map<String, dynamic> toJson() => {
        'role': role,
        'completed_step_ids': completedStepIds,
        'total_steps': totalSteps,
        'skipped': skipped,
        'completed': completed,
        'percentage': percentage,
        'updated_at': updatedAt.toIso8601String(),
      };
}

class CommercialReadiness {
  final int score;
  final Map<String, LaunchCheckStatus> plans;
  final bool pricingReady;
  final bool landingReady;
  final bool documentationReady;
  final bool supportReady;
  final bool onboardingReady;
  final bool demoReady;
  final List<String> pendingItems;

  const CommercialReadiness({
    this.score = 0,
    this.plans = const {},
    this.pricingReady = false,
    this.landingReady = false,
    this.documentationReady = false,
    this.supportReady = false,
    this.onboardingReady = false,
    this.demoReady = false,
    this.pendingItems = const [],
  });
}

class BetaProgramSummary {
  final bool feedbackChannelReady;
  final int criticalFlowCount;
  final FeedbackSummary feedback;
  final List<String> nextSteps;

  const BetaProgramSummary({
    this.feedbackChannelReady = false,
    this.criticalFlowCount = 0,
    this.feedback = const FeedbackSummary(),
    this.nextSteps = const [],
  });
}

T _enumValue<T extends Enum>(List<T> values, dynamic raw, T fallback) {
  final name = raw?.toString().trim() ?? '';
  return values.firstWhere((value) => value.name == name,
      orElse: () => fallback);
}

String _text(dynamic value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value) =>
    value is num ? value.round() : int.tryParse('${value ?? ''}') ?? 0;

DateTime _date(dynamic value) =>
    DateTime.tryParse(_text(value)) ?? DateTime.fromMillisecondsSinceEpoch(0);

List<String> _strings(dynamic value) => value is List
    ? value.map((item) => _text(item)).where((item) => item.isNotEmpty).toList()
    : const [];

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
    : const [];
