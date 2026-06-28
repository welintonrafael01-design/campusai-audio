import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/study_result.dart';
import '../study_result_service.dart';
import 'ftue_models.dart';

/// Local-first first-time experience layered on top of existing onboarding.
class FtueService {
  static const progressType = 'ftue_progress';

  const FtueService();

  List<FtueStep> stepsForPath(FtueUserPath path) {
    return switch (path) {
      FtueUserPath.free => const [
          FtueStep(
            id: 'free_content',
            title: 'Pega tu primer contenido',
            description: 'Empieza con un texto breve que quieras comprender.',
            actionLabel: 'Crear contenido',
            routeName: 'audioBookStudio',
            userPath: FtueUserPath.free,
          ),
          FtueStep(
            id: 'free_audiobook',
            title: 'Escúchalo como AudioBook',
            description: 'Booky lo convierte en aprendizaje escuchable.',
            actionLabel: 'Crear AudioBook',
            routeName: 'audioBookStudio',
            userPath: FtueUserPath.free,
          ),
          FtueStep(
            id: 'free_booky',
            title: 'Haz tu primera pregunta',
            description: 'Pide una explicación sencilla o un repaso.',
            actionLabel: 'Preguntar a Booky',
            routeName: 'voiceTutor',
            userPath: FtueUserPath.free,
          ),
        ],
      FtueUserPath.student => const [
          FtueStep(
            id: 'student_content',
            title: 'Sube o pega contenido',
            description:
                'Elige cualquier tema, texto o documento para empezar.',
            actionLabel: 'Añadir contenido',
            routeName: 'audioBookStudio',
            userPath: FtueUserPath.student,
          ),
          FtueStep(
            id: 'student_audiobook',
            title: 'Crea tu primer AudioBook',
            description: 'Booky prepara audio, resumen, flashcards y quiz.',
            actionLabel: 'Crear AudioBook',
            routeName: 'audioBookStudio',
            userPath: FtueUserPath.student,
          ),
          FtueStep(
            id: 'student_quiz',
            title: 'Completa un mini quiz',
            description: 'Comprueba lo aprendido con preguntas breves.',
            actionLabel: 'Practicar',
            routeName: 'audioBookStudio',
            userPath: FtueUserPath.student,
          ),
          FtueStep(
            id: 'student_booky',
            title: 'Pregúntale a Booky',
            description: 'Pide una explicación o repasa a tu ritmo.',
            actionLabel: 'Abrir Tutor IA',
            routeName: 'voiceTutor',
            userPath: FtueUserPath.student,
          ),
          FtueStep(
            id: 'student_progress',
            title: 'Mira tu progreso',
            description: 'Descubre cuánto avanzaste y cuál es tu próximo paso.',
            actionLabel: 'Ver progreso',
            routeName: 'studentDashboard',
            userPath: FtueUserPath.student,
            estimatedMinutes: 1,
          ),
        ],
      FtueUserPath.teacher => const [
          FtueStep(
            id: 'teacher_course',
            title: 'Crea tu primer curso',
            description: 'Organiza contenido, unidades y estudiantes.',
            actionLabel: 'Crear curso',
            routeName: 'courses',
            userPath: FtueUserPath.teacher,
          ),
          FtueStep(
            id: 'teacher_plan',
            title: 'Genera una planificación en minutos',
            description:
                'Convierte el contenido del curso en una ruta docente.',
            actionLabel: 'Abrir cursos',
            routeName: 'courses',
            userPath: FtueUserPath.teacher,
          ),
          FtueStep(
            id: 'teacher_resource',
            title: 'Crea tu primer recurso',
            description: 'Prepara rúbricas y exámenes con ayuda de Booky.',
            actionLabel: 'Crear recurso',
            routeName: 'courses',
            userPath: FtueUserPath.teacher,
          ),
        ],
      FtueUserPath.accessibility => const [
          FtueStep(
            id: 'accessibility_preferences',
            title: 'Aprende a tu manera',
            description:
                'Elige audio, texto grande, lenguaje simple o contraste.',
            actionLabel: 'Ajustar preferencias',
            routeName: 'studentDashboard',
            userPath: FtueUserPath.accessibility,
          ),
          FtueStep(
            id: 'accessibility_audio',
            title: 'Escucha el contenido',
            description:
                'Usa AudioBook si aprender con audio te resulta mejor.',
            actionLabel: 'Probar AudioBook',
            routeName: 'audioBookStudio',
            userPath: FtueUserPath.accessibility,
          ),
          FtueStep(
            id: 'accessibility_steps',
            title: 'Practica paso a paso',
            description: 'Pide lenguaje simple y preguntas cortas a Booky.',
            actionLabel: 'Hablar con Booky',
            routeName: 'voiceTutor',
            userPath: FtueUserPath.accessibility,
          ),
        ],
    };
  }

  Future<FtueProgress> load(FtueUserPath path) async {
    try {
      final result = await StudyResultService.getResult(
        documentId: _documentId(path),
        type: progressType,
      );
      if (result == null) return FtueProgress.initial(path);
      final decoded = jsonDecode(result.content);
      if (decoded is Map) {
        return FtueProgress.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (error) {
      debugPrint('FtueService.load: $error');
    }
    return FtueProgress.initial(path);
  }

  Future<FtueProgress> completeStep(
    FtueProgress progress,
    String stepId,
  ) async {
    final validIds = stepsForPath(progress.userPath).map((step) => step.id);
    if (!validIds.contains(stepId) || progress.isStepComplete(stepId)) {
      return progress;
    }
    final updated = progress.copyWith(
      completedStepIds: {...progress.completedStepIds, stepId}.toList(),
    );
    await save(updated);
    return updated;
  }

  Future<FtueProgress> dismiss(FtueProgress progress) async {
    final updated = progress.copyWith(dismissed: true);
    await save(updated);
    return updated;
  }

  Future<FtueProgress> synchronizeStudentActivity(
    FtueProgress progress, {
    required bool hasAudioBook,
    required bool hasQuiz,
    required bool hasLearningActivity,
  }) async {
    if (progress.userPath != FtueUserPath.student) return progress;
    final completed = {...progress.completedStepIds};
    if (hasAudioBook) {
      completed.addAll(const ['student_content', 'student_audiobook']);
    }
    if (hasQuiz) completed.add('student_quiz');
    if (await _hasBookyConversation()) completed.add('student_booky');
    if (hasLearningActivity) completed.add('student_progress');
    if (completed.length == progress.completedStepIds.length) return progress;

    final updated = progress.copyWith(completedStepIds: completed.toList());
    await save(updated);
    return updated;
  }

  Future<bool> save(FtueProgress progress) async {
    try {
      await StudyResultService.saveResult(
        StudyResult(
          documentId: _documentId(progress.userPath),
          type: progressType,
          content: jsonEncode(progress.toJson()),
          createdAt: progress.updatedAt.toIso8601String(),
        ),
      );
      return true;
    } catch (error) {
      debugPrint('FtueService.save: $error');
      return false;
    }
  }

  Future<bool> _hasBookyConversation() async {
    final sessions = await StudyResultService.getResultsByType('voice_session');
    for (final session in sessions) {
      try {
        final decoded = jsonDecode(session.content);
        if (decoded is Map && decoded['messages'] is List) {
          final messages = decoded['messages'] as List;
          if (messages.any((message) =>
              message is Map && message['role']?.toString() == 'user')) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  String _documentId(FtueUserPath path) => 'ftue_progress_${path.name}';
}
