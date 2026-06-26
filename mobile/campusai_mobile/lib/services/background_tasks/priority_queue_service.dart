import 'background_task_models.dart';

class PriorityQueueService {
  List<BackgroundTask> sort(List<BackgroundTask> tasks) =>
      [...tasks]..sort((a, b) => a.priority.compareTo(b.priority));
}
