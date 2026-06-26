import 'local_telemetry_service.dart';

class EventRecorder {
  final LocalTelemetryService telemetry;
  EventRecorder({LocalTelemetryService? telemetry})
      : telemetry = telemetry ?? LocalTelemetryService();
  void record(String event) => telemetry.record(event);
}
