import 'task_queue_service.dart';

class BackgroundWorkerService {
  final TaskQueueService queue;
  BackgroundWorkerService({TaskQueueService? queue})
      : queue = queue ?? TaskQueueService();
}
