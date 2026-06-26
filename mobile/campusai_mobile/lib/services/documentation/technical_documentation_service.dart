import '../campus_intelligence/enterprise_result_repository.dart';
import 'architecture_inventory_service.dart';
import 'documentation_models.dart';
import 'service_inventory_service.dart';

class TechnicalDocumentationService {
  final EnterpriseResultRepository repository;
  final ServiceInventoryService serviceInventoryService;
  final ArchitectureInventoryService architectureInventoryService;

  const TechnicalDocumentationService({
    this.repository = const EnterpriseResultRepository(),
    this.serviceInventoryService = const ServiceInventoryService(),
    this.architectureInventoryService = const ArchitectureInventoryService(),
  });

  Future<TechnicalDocumentation> buildDocumentation() async {
    final services = await serviceInventoryService.buildInventory();
    final documentation = TechnicalDocumentation(
      modules: architectureInventoryService.buildModules(),
      services: services,
      dataFlows: architectureInventoryService.buildDataFlows(),
      studyResultTypes: architectureInventoryService.buildStudyResultTypes(),
    );
    await repository.save(
      documentId: 'technical_documentation_latest',
      type: 'technical_documentation',
      payload: documentation.toJson(),
    );
    return documentation;
  }
}
