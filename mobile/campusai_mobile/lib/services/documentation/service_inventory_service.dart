import '../campus_intelligence/enterprise_result_repository.dart';
import 'documentation_models.dart';

class ServiceInventoryService {
  final EnterpriseResultRepository repository;
  const ServiceInventoryService({
    this.repository = const EnterpriseResultRepository(),
  });

  Future<List<ServiceInventoryItem>> buildInventory() async {
    final inventory = const [
      ServiceInventoryItem(name: 'Academic Engine', module: 'Teacher Studio'),
      ServiceInventoryItem(name: 'Learning Engine', module: 'Student Studio'),
      ServiceInventoryItem(name: 'Voice Intelligence', module: 'Voice'),
      ServiceInventoryItem(
        name: 'StudyBook AI Intelligence',
        module: 'StudyBook AI',
      ),
      ServiceInventoryItem(name: 'Marketplace Service', module: 'Marketplace'),
      ServiceInventoryItem(name: 'Institution Service', module: 'Institution'),
      ServiceInventoryItem(name: 'Gamification Service', module: 'Student'),
      ServiceInventoryItem(name: 'Security Scan Service', module: 'Security'),
      ServiceInventoryItem(name: 'Observability Services', module: 'Ops'),
      ServiceInventoryItem(name: 'Production Cache', module: 'Performance'),
    ];
    await repository.save(
      documentId: 'service_inventory_latest',
      type: 'service_inventory',
      payload: {'services': inventory.map((item) => item.toJson()).toList()},
    );
    return inventory;
  }
}
