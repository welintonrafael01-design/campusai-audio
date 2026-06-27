import 'launch_models.dart';

/// Defines lightweight, role-aware paths using routes that already exist.
class OnboardingFlowService {
  const OnboardingFlowService();

  List<OnboardingStep> stepsForRole(String role) {
    return role.trim().toLowerCase() == 'teacher'
        ? const [
            OnboardingStep(
              id: 'teacher_dashboard',
              title: 'Conoce tu espacio docente',
              description: 'Revisa cursos y recursos desde el Dashboard.',
              role: 'teacher',
              routeName: 'dashboard',
            ),
            OnboardingStep(
              id: 'teacher_course',
              title: 'Crea tu primer curso',
              description: 'Organiza documentos, unidades y estudiantes.',
              role: 'teacher',
              routeName: 'courses',
            ),
            OnboardingStep(
              id: 'teacher_resource',
              title: 'Genera un recurso académico',
              description: 'Crea un banco, examen, rúbrica o guía por unidad.',
              role: 'teacher',
              routeName: 'courses',
            ),
          ]
        : const [
            OnboardingStep(
              id: 'student_dashboard',
              title: 'Conoce tu plan inteligente',
              description: 'Encuentra tu siguiente mejor acción.',
              role: 'student',
              routeName: 'studentDashboard',
            ),
            OnboardingStep(
              id: 'student_audiobook',
              title: 'Crea o escucha un AudioBook',
              description: 'Aprende con audio, flashcards y mini quiz.',
              role: 'student',
              routeName: 'audioBookStudio',
            ),
            OnboardingStep(
              id: 'student_tutor',
              title: 'Habla con el Tutor IA',
              description: 'Pide explicaciones y practica a tu ritmo.',
              role: 'student',
              routeName: 'voiceTutor',
            ),
          ];
  }
}
