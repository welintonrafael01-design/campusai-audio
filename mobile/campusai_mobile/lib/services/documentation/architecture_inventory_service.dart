import 'documentation_models.dart';

class ArchitectureInventoryService {
  const ArchitectureInventoryService();

  List<ModuleInventoryItem> buildModules() => const [
        ModuleInventoryItem(name: 'Teacher Studio'),
        ModuleInventoryItem(name: 'Academic Engine'),
        ModuleInventoryItem(name: 'Student Studio'),
        ModuleInventoryItem(name: 'AudioBook Studio'),
        ModuleInventoryItem(name: 'Voice Intelligence'),
        ModuleInventoryItem(name: 'CampusAI Intelligence'),
        ModuleInventoryItem(
            name: 'Marketplace Foundation', status: 'foundation'),
        ModuleInventoryItem(name: 'Institution Platform', status: 'foundation'),
        ModuleInventoryItem(name: 'Security Foundation'),
        ModuleInventoryItem(name: 'Observability Foundation'),
      ];

  List<String> buildDataFlows() => const [
        'Usuario -> Flutter UI -> Services -> StudyResultService',
        'Academic Engine -> StudyResult -> Educator/Teacher views',
        'Learning Engine -> Student Dashboard -> Local analytics',
        'Enterprise layers -> EnterpriseResultRepository -> StudyResult',
      ];

  List<String> buildStudyResultTypes() => const [
        'teaching_plan',
        'question_bank',
        'exam',
        'rubric',
        'study_guide',
        'assessment_report',
        'workflow_execution',
        'decision_history',
        'release_candidate_report',
        'qa_report',
        'technical_documentation',
      ];
}
