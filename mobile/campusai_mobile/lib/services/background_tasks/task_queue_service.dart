import 'background_task_models.dart';

class TaskQueueService {
  final List<BackgroundTask> tasks = [];
  void add(BackgroundTask task) => tasks.add(task);
  BackgroundTask? take() => tasks.isEmpty ? null : tasks.removeAt(0);
}
