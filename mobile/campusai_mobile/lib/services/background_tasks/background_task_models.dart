class BackgroundTask {
  final String id;
  final int priority;
  final int attempts;
  const BackgroundTask({this.id = '', this.priority = 3, this.attempts = 0});
}
