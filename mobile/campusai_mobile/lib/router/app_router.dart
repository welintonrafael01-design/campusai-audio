import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/chat_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/exam_screen.dart';
import '../screens/flashcards_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/admin_analytics_screen.dart';
import '../screens/plans_screen.dart';
import '../screens/library_screen.dart';
import '../screens/reset_password_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(
      path: '/auth',
      name: 'auth',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const AuthScreen(),
        );
      },
    ),

    GoRoute(
      path: '/reset-password',
      name: 'reset-password',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const ResetPasswordScreen(),
        );
      },
    ),
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

        final cloudChatId = state.uri.queryParameters['cloudChatId'] ?? '';

        final workspaceId = state.uri.queryParameters['workspaceId'] ?? '';

        final workspaceIdsRaw = state.uri.queryParameters['workspaceIds'] ?? '';

        final workspaceDocumentIds = workspaceIdsRaw
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();

        return _buildPage(
          state: state,
          child: ChatScreen(
            documentId: documentId,
            fileName: fileName,
            workspaceId: workspaceId,
            workspaceDocumentIds: workspaceDocumentIds,
            cloudChatId: cloudChatId,
          ),
        );
      },
    ),
    GoRoute(
      path: '/exam/:documentId',
      name: 'exam',
      pageBuilder: (context, state) {
        final documentId = state.pathParameters['documentId'] ?? '';

        final initialQuestions = state.extra is List
            ? (state.extra as List)
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
            : <Map<String, dynamic>>[];

        return _buildPage(
          state: state,
          child: ExamScreen(
            documentId: documentId,
            initialQuestions: initialQuestions,
          ),
        );
      },
    ),
    GoRoute(
      path: '/flashcards/:documentId',
      name: 'flashcards',
      pageBuilder: (context, state) {
        final documentId = state.pathParameters['documentId'] ?? '';

        final initialFlashcards = state.extra is List
            ? (state.extra as List)
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
            : <Map<String, dynamic>>[];

        return _buildPage(
          state: state,
          child: FlashcardsScreen(
            documentId: documentId,
            initialFlashcards: initialFlashcards,
          ),
        );
      },
    ),
    GoRoute(
      path: '/admin',
      name: 'admin',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const AdminAnalyticsScreen(),
        );
      },
    ),
    GoRoute(
      path: '/library',
      name: 'library',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const LibraryScreen(),
        );
      },
    ),
    GoRoute(
      path: '/plans',
      name: 'plans',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const PlansScreen(),
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
