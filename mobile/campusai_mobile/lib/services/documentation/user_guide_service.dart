import 'documentation_models.dart';

class UserGuideService {
  const UserGuideService();

  List<UserGuideSection> buildUserGuide() => const [
        UserGuideSection(
          title: 'Teacher Studio',
          steps: ['Crear curso', 'Generar plan docente', 'Abrir unidad'],
        ),
        UserGuideSection(
          title: 'Student Studio',
          steps: [
            'Abrir dashboard',
            'Continuar aprendizaje',
            'Revisar progreso'
          ],
        ),
        UserGuideSection(
          title: 'Voice Tutor',
          steps: [
            'Abrir tutor',
            'Enviar texto o usar micrófono',
            'Revisar respuesta'
          ],
        ),
      ];
}
