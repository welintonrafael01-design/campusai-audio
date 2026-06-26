class ExecutionMetricsService {
  const ExecutionMetricsService();
  Map<String, num> metrics(Duration duration) =>
      {'milliseconds': duration.inMilliseconds};
}
