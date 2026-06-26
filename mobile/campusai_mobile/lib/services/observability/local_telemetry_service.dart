class LocalTelemetryService {
  final List<String> events = [];
  void record(String event) {
    events.add(event);
  }
}
