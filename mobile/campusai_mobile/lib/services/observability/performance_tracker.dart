class PerformanceTracker {
  const PerformanceTracker();
  DateTime start() => DateTime.now();
  Duration stop(DateTime value) => DateTime.now().difference(value);
}
