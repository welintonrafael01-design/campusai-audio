class CrashRecorder {
  const CrashRecorder();
  String record(Object error) => error.runtimeType.toString();
}
