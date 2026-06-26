import '../campus_intelligence/enterprise_result_repository.dart';

class InstitutionWorkspace {
  final String id;
  final List<String> departments;
  final List<String> programs;
  final List<String> courses;
  final List<String> teachers;
  final List<String> students;
  final Map<String, dynamic> analytics;
  final Map<String, dynamic> prediction;
  final Map<String, dynamic> health;
  final List<String> alerts;
  final List<String> resources;
  final List<String> knowledgeBase;
  final List<String> academicCalendar;

  const InstitutionWorkspace({
    this.id = 'institution_workspace_local',
    this.departments = const [],
    this.programs = const [],
    this.courses = const [],
    this.teachers = const [],
    this.students = const [],
    this.analytics = const {},
    this.prediction = const {},
    this.health = const {},
    this.alerts = const [],
    this.resources = const [],
    this.knowledgeBase = const [],
    this.academicCalendar = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'departments': departments,
        'programs': programs,
        'courses': courses,
        'teachers': teachers,
        'students': students,
        'analytics': analytics,
        'prediction': prediction,
        'health': health,
        'alerts': alerts,
        'resources': resources,
        'knowledge_base': knowledgeBase,
        'academic_calendar': academicCalendar,
      };
}

class InstitutionWorkspaceService {
  final EnterpriseResultRepository repository;
  const InstitutionWorkspaceService({
    this.repository = const EnterpriseResultRepository(),
  });

  Future<void> save(InstitutionWorkspace workspace) => repository.save(
        documentId: workspace.id,
        type: 'institution_workspace',
        payload: workspace.toJson(),
      );

  InstitutionWorkspace empty() => const InstitutionWorkspace();
}
