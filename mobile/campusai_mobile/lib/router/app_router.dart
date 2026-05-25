import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/chat_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/exam_screen.dart';
import '../screens/flashcards_screen.dart';
import '../screens/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const DashboardScreen(),
        );
      },
    ),
    GoRoute(
      path: '/chat/:documentId',
      name: 'chat',
      pageBuilder: (context, state) {
        final documentId = state.pathParameters['documentId'] ?? '';
        final fileName =
            state.uri.queryParameters['fileName'] ?? 'Documento activo';

        return _buildPage(
          state: state,
          child: ChatScreen(
            documentId: documentId,
            fileName: fileName,
          ),
        );
      },
    ),
    GoRoute(
      path: '/exam/:documentId',
      name: 'exam',
      pageBuilder: (context, state) {
        final documentId = state.pathParameters['documentId'] ?? '';

        return _buildPage(
          state: state,
          child: ExamScreen(
            documentId: documentId,
          ),
        );
      },
    ),
    GoRoute(
      path: '/flashcards/:documentId',
      name: 'flashcards',
      pageBuilder: (context, state) {
        final documentId = state.pathParameters['documentId'] ?? '';

        return _buildPage(
          state: state,
          child: FlashcardsScreen(
            documentId: documentId,
          ),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const SettingsScreen(),
        );
      },
    ),
  ],
);

CustomTransitionPage<void> _buildPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.025, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
  );
}