import '../campus_intelligence/enterprise_result_repository.dart';
import 'qa_models.dart';

class QaScenarioService {
  final EnterpriseResultRepository repository;
  const QaScenarioService({
    this.repository = const EnterpriseResultRepository(),
  });

  List<QaScenario> buildCriticalScenarios() => const [
        QaScenario(id: 'login', title: 'Login', area: 'Auth'),
        QaScenario(id: 'dashboard', title: 'Dashboard', area: 'Core'),
        QaScenario(
          id: 'teacher_studio',
          title: 'Teacher Studio',
          area: 'Teacher',
        ),
        QaScenario(id: 'create_course', title: 'Crear curso', area: 'Courses'),
        QaScenario(
          id: 'teaching_plan',
          title: 'Plan docente',
          area: 'Academic Engine',
        ),
        QaScenario(
          id: 'unit_workspace',
          title: 'Unit Workspace',
          area: 'Teacher',
        ),
        QaScenario(id: 'audiobook', title: 'AudioBook', area: 'Audio'),
        QaScenario(
          id: 'learning_pack',
          title: 'Learning Pack',
          area: 'Student',
        ),
        QaScenario(id: 'mini_quiz', title: 'Mini Quiz', area: 'Student'),
        QaScenario(
          id: 'student_dashboard',
          title: 'Student Dashboard',
          area: 'Student',
        ),
        QaScenario(
          id: 'voice_tutor_text',
          title: 'Voice Tutor texto',
          area: 'Voice',
        ),
        QaScenario(
          id: 'voice_tutor_microphone',
          title: 'Voice Tutor micrófono',
          area: 'Voice',
        ),
        QaScenario(
          id: 'campusai_dashboard',
          title: 'StudyBook AI Dashboard',
          area: 'StudyBook AI',
        ),
        QaScenario(
          id: 'gamification',
          title: 'Gamification',
          area: 'Student',
        ),
        QaScenario(
          id: 'marketplace_local',
          title: 'Marketplace local',
          area: 'Marketplace',
        ),
        QaScenario(
          id: 'institution_local',
          title: 'Institution local',
          area: 'Institution',
        ),
        QaScenario(
            id: 'billing_basic', title: 'Billing básico', area: 'Billing'),
      ];

  Future<void> saveScenarios(List<QaScenario> scenarios) async {
    for (final scenario in scenarios) {
      await repository.save(
        documentId: 'qa_scenario_${scenario.id}',
        type: 'qa_scenario',
        payload: scenario.toJson(),
      );
    }
  }
}
