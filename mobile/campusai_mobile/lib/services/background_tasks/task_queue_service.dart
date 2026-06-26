import 'background_task_models.dart';

class TaskQueueService {
  final List<BackgroundTask> tasks = [];
  void add(BackgroundTask task) => tasks.add(task);
  BackgroundTask? take() {
    final available = tasks
        .where((task) =>
            !task.cancelled &&
            (task.scheduledAt == null ||
                !task.scheduledAt!.isAfter(DateTime.now())))
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    if (available.isEmpty) return null;
    final task = available.first;
    tasks.remove(task);
    return task;
  }

  void cancel(String taskId) {
    final index = tasks.indexWhere((task) => task.id == taskId);
    if (index >= 0) {
      tasks[index] = tasks[index].copyWith(cancelled: true);
    }
  }
}

class TaskWorker {
  final TaskQueueService queue;
  final RetryPolicy retryPolicy;
  const TaskWorker({
    required this.queue,
    this.retryPolicy = const RetryPolicy(),
  });

  Future<BackgroundTask?> next() async => queue.take();
}

class PriorityScheduler {
  final TaskQueueService queue;
  const PriorityScheduler(this.queue);
  void schedule(BackgroundTask task) => queue.add(task);
}
