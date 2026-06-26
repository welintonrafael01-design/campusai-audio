class BackgroundTask {
  final String id;
  final int priority;
  final int attempts;
  final DateTime? scheduledAt;
  final Duration? recurringEvery;
  final bool cancelled;
  const BackgroundTask({
    this.id = '',
    this.priority = 3,
    this.attempts = 0,
    this.scheduledAt,
    this.recurringEvery,
    this.cancelled = false,
  });

  BackgroundTask copyWith({
    String? id,
    int? priority,
    int? attempts,
    DateTime? scheduledAt,
    Duration? recurringEvery,
    bool? cancelled,
  }) =>
      BackgroundTask(
        id: id ?? this.id,
        priority: priority ?? this.priority,
        attempts: attempts ?? this.attempts,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        recurringEvery: recurringEvery ?? this.recurringEvery,
        cancelled: cancelled ?? this.cancelled,
      );
}

class RetryPolicy {
  final int maxAttempts;
  final Duration delay;
  const RetryPolicy({
    this.maxAttempts = 3,
    this.delay = const Duration(seconds: 2),
  });

  bool canRetry(BackgroundTask task) => task.attempts < maxAttempts;
}

class CancellationToken {
  bool _cancelled = false;
  bool get cancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class DelayedTask extends BackgroundTask {
  const DelayedTask({
    super.id,
    super.priority,
    super.attempts,
    required DateTime runAt,
  }) : super(scheduledAt: runAt);
}

class RecurringTask extends BackgroundTask {
  const RecurringTask({
    super.id,
    super.priority,
    super.attempts,
    required Duration every,
  }) : super(recurringEvery: every);
}
