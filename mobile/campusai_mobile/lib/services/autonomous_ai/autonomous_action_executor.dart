import 'dart:async';

import 'autonomous_action_models.dart';
import 'autonomous_action_repository.dart';

typedef AutonomousNavigationHandler = FutureOr<void> Function(
  String route,
  Map<String, dynamic> extra,
);

/// Ejecuta únicamente navegación local segura y registra el resultado.
class AutonomousActionExecutor {
  final AutonomousActionRepository repository;

  const AutonomousActionExecutor({
    this.repository = const AutonomousActionRepository(),
  });

  Future<AutonomousActionResult> execute(
    AutonomousAction action, {
    AutonomousNavigationHandler? navigate,
  }) async {
    if (action.status != AutonomousActionStatus.pending) {
      return _result(
        action,
        AutonomousActionStatus.failed,
        'La acción ya fue procesada.',
      );
    }
    try {
      final destination = _destination(action);
      if (destination.route.isNotEmpty && navigate != null) {
        await Future<void>.sync(
          () => navigate(destination.route, destination.extra),
        );
      }
      final completed = action.copyWith(
        status: AutonomousActionStatus.completed,
        updatedAt: DateTime.now(),
      );
      await repository.updateActionStatus(completed);
      final result = _result(
        action,
        AutonomousActionStatus.completed,
        destination.message,
        route: destination.route,
      );
      await repository.recordResult(result);
      return result;
    } catch (_) {
      final failed = action.copyWith(
        status: AutonomousActionStatus.failed,
        updatedAt: DateTime.now(),
      );
      await repository.updateActionStatus(failed);
      final result = _result(
        action,
        AutonomousActionStatus.failed,
        'No se pudo ejecutar esta acción.',
      );
      await repository.recordResult(result);
      return result;
    }
  }

  Future<AutonomousActionResult> dismiss(AutonomousAction action) async {
    final dismissed = action.copyWith(
      status: AutonomousActionStatus.dismissed,
      updatedAt: DateTime.now(),
    );
    await repository.updateActionStatus(dismissed);
    final result = _result(
      action,
      AutonomousActionStatus.dismissed,
      'Acción descartada.',
    );
    await repository.recordResult(result);
    return result;
  }

  _ActionDestination _destination(AutonomousAction action) {
    return switch (action.type) {
      AutonomousActionTypes.continueAudiobook => _ActionDestination(
          route: 'audioBookStudio',
          message: 'Abriendo AudioBook Studio.',
          extra: {
            'sourceMode': 'solo',
            'sourceType': 'text',
            'audiobookId': action.metadata['audiobook_id'] ?? action.targetId,
            'chapterId': action.metadata['chapter_id'] ?? '',
          },
        ),
      AutonomousActionTypes.talkToTutor ||
      AutonomousActionTypes.reviewWeakness ||
      AutonomousActionTypes.takeQuiz ||
      AutonomousActionTypes.reviewFlashcards =>
        _ActionDestination(
          route: 'voiceTutor',
          message: 'Abriendo Tutor IA.',
          extra: {
            'title': action.title,
            'autonomous_action_id': action.id,
            'suggested_prompt': action.reason,
          },
        ),
      AutonomousActionTypes.followSmartPlan ||
      AutonomousActionTypes.studyNow ||
      AutonomousActionTypes.maintainStreak =>
        const _ActionDestination(
          route: 'studentDashboard',
          message: 'Plan inteligente actualizado.',
        ),
      AutonomousActionTypes.exploreMarketplaceResource =>
        const _ActionDestination(
          message: 'Recurso destacado en tus recomendaciones.',
        ),
      AutonomousActionTypes.rest => const _ActionDestination(
          message: 'Pausa registrada. Retoma cuando estés listo.',
        ),
      AutonomousActionTypes.teacherIntervention ||
      AutonomousActionTypes.institutionAlert =>
        const _ActionDestination(
          message: 'Alerta revisada.',
        ),
      _ => const _ActionDestination(message: 'Acción completada.'),
    };
  }

  AutonomousActionResult _result(
    AutonomousAction action,
    AutonomousActionStatus status,
    String message, {
    String route = '',
  }) {
    return AutonomousActionResult(
      actionId: action.id,
      status: status,
      message: message,
      route: route,
      executedAt: DateTime.now(),
    );
  }
}

class _ActionDestination {
  final String route;
  final String message;
  final Map<String, dynamic> extra;

  const _ActionDestination({
    this.route = '',
    required this.message,
    this.extra = const {},
  });
}
