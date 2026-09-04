import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/chat_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/certificate_verify_screen.dart';
import '../screens/exam_screen.dart';
import '../screens/flashcards_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/admin_analytics_screen.dart';
import '../screens/plans_screen.dart';
import '../screens/admin/financial_dashboard_screen.dart';
import '../screens/library_screen.dart';
import '../screens/question_bank_screen.dart';
import '../screens/rubric_screen.dart';
import '../screens/gradebook_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/final_report_screen.dart';
import '../screens/academic_dashboard_screen.dart';
import '../screens/academic_recognition_screen.dart';
import '../screens/student_profile_screen.dart';
import '../screens/student_dashboard_screen.dart';
import '../screens/student_transcript_screen.dart';
import '../screens/assessment_weights_screen.dart';
import '../screens/courses_screen.dart';
import '../screens/students_screen.dart';
import '../screens/saved_exams_screen.dart';
import '../screens/teaching_plan_screen.dart';
import '../screens/unit_workspace_screen.dart';
import '../screens/audiobook_studio_screen.dart';
import '../screens/voice_tutor_screen.dart';
import '../screens/reset_password_screen.dart';
import '../services/access_control_service.dart';
import 'auth_route_refresh_notifier.dart';

final appRouter = GoRouter(
  initialLocation: '/auth',
  refreshListenable: authRouteRefreshNotifier,
  redirect: (context, state) {
    final path = state.uri.path;
    return const AccessControlService().redirectForPath(path);
  },
  routes: [
    GoRoute(
      path: '/student-transcript',
      name: 'student-transcript',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};

        return StudentTranscriptScreen(
          studentCode: extra['studentCode']?.toString() ?? '',
          studentName: extra['studentName']?.toString() ?? '',
        );
      },
    ),
    GoRoute(
      path: '/verify/:certificateId',
      name: 'certificate-verify',
      builder: (context, state) {
        return CertificateVerifyScreen(
          certificateId: state.pathParameters['certificateId'] ?? '',
        );
      },
    ),
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
      path: '/audiobook-studio',
      name: 'audioBookStudio',
      pageBuilder: (context, state) {
        final extra = state.extra is Map
            ? Map<String, dynamic>.from(state.extra as Map)
            : <String, dynamic>{};

        return _buildPage(
          state: state,
          child: AudioBookStudioScreen(
            sourceMode: extra['sourceMode']?.toString() ??
                extra['source_mode']?.toString() ??
                'solo',
            sourceType: extra['sourceType']?.toString() ??
                extra['source_type']?.toString() ??
                'text',
            sourceDocumentId: extra['sourceDocumentId']?.toString() ??
                extra['source_document_id']?.toString() ??
                '',
            courseId: extra['courseId']?.toString() ??
                extra['course_id']?.toString() ??
                '',
            courseName: extra['courseName']?.toString() ??
                extra['course_name']?.toString() ??
                '',
            unitId: extra['unitId']?.toString() ??
                extra['unit_id']?.toString() ??
                '',
            unitTopic: extra['unitTopic']?.toString() ??
                extra['unit_topic']?.toString() ??
                '',
            initialTitle: extra['initialTitle']?.toString() ?? '',
            initialText: extra['initialText']?.toString() ?? '',
          ),
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
      path: '/student-dashboard',
      name: 'studentDashboard',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const StudentDashboardScreen(),
        );
      },
    ),
    GoRoute(
      path: '/learning',
      name: 'learning',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const StudentDashboardScreen(),
        );
      },
    ),
    GoRoute(
      path: '/teacher',
      name: 'teacher',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const CoursesScreen(),
        );
      },
    ),
    GoRoute(
      path: '/account',
      name: 'account',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const SettingsScreen(),
        );
      },
    ),
    GoRoute(
      path: '/voice-tutor',
      name: 'voiceTutor',
      pageBuilder: (context, state) {
        final extra = state.extra is Map
            ? Map<String, dynamic>.from(state.extra as Map)
            : <String, dynamic>{};

        return _buildPage(
          state: state,
          child: VoiceTutorScreen(
            audiobookId: extra['audiobookId']?.toString() ??
                extra['audiobook_id']?.toString() ??
                '',
            chapterId: extra['chapterId']?.toString() ??
                extra['chapter_id']?.toString() ??
                '',
            title: extra['title']?.toString() ?? '',
            sessionId: extra['sessionId']?.toString() ??
                extra['session_id']?.toString() ??
                '',
            payload: extra,
          ),
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
            practiceMode: state.uri.queryParameters['mode'] == 'practice',
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
      path: '/rubric/:documentId',
      name: 'rubric',
      pageBuilder: (context, state) {
        final documentId = state.pathParameters['documentId'] ?? '';

        final initialRubric = state.extra is Map
            ? Map<String, dynamic>.from(state.extra as Map)
            : <String, dynamic>{};

        return _buildPage(
          state: state,
          child: RubricScreen(
            documentId: documentId,
            initialRubric: initialRubric,
          ),
        );
      },
    ),
    GoRoute(
      path: '/question-bank/:documentId',
      name: 'question-bank',
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
          child: QuestionBankScreen(
            documentId: documentId,
            initialQuestions: initialQuestions,
          ),
        );
      },
    ),
    GoRoute(
      path: '/teaching-plan/:documentId',
      name: 'teaching-plan',
      pageBuilder: (context, state) {
        final documentId = state.pathParameters['documentId'] ?? '';

        final initialPlan = state.extra is Map
            ? Map<String, dynamic>.from(state.extra as Map)
            : <String, dynamic>{};

        return _buildPage(
          state: state,
          child: TeachingPlanScreen(
            documentId: documentId,
            initialPlan: initialPlan,
          ),
        );
      },
    ),
    GoRoute(
      path: '/unit-workspace',
      name: 'unitWorkspace',
      pageBuilder: (context, state) {
        final extra = state.extra is Map
            ? Map<String, dynamic>.from(state.extra as Map)
            : <String, dynamic>{};
        final plan = extra['plan'] is Map
            ? Map<String, dynamic>.from(extra['plan'] as Map)
            : <String, dynamic>{};
        final week = extra['week'] is Map
            ? Map<String, dynamic>.from(extra['week'] as Map)
            : <String, dynamic>{};
        final rawWeekIndex = extra['weekIndex'];
        final weekIndex = rawWeekIndex is int
            ? rawWeekIndex
            : int.tryParse(rawWeekIndex?.toString() ?? '') ?? 0;

        return _buildPage(
          state: state,
          child: UnitWorkspaceScreen(
            teachingPlanDocumentId:
                extra['teachingPlanDocumentId']?.toString() ?? '',
            plan: plan,
            week: week,
            weekIndex: weekIndex,
          ),
        );
      },
    ),
    GoRoute(
      path: '/students',
      name: 'students',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const StudentsScreen(),
        );
      },
    ),
    GoRoute(
      path: '/courses',
      name: 'courses',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const CoursesScreen(),
        );
      },
    ),
    GoRoute(
      path: '/assessment-weights',
      name: 'assessment-weights',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const AssessmentWeightsScreen(),
        );
      },
    ),
    GoRoute(
      path: '/student-profile',
      name: 'student-profile',
      pageBuilder: (context, state) {
        final params = state.extra is Map
            ? Map<String, dynamic>.from(state.extra as Map)
            : <String, dynamic>{};

        return _buildPage(
          state: state,
          child: StudentProfileScreen(
            studentCode: params['studentCode']?.toString() ?? '',
            studentName: params['studentName']?.toString() ?? '',
            courseId: params['courseId']?.toString() ?? '',
            courseName: params['courseName']?.toString() ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: '/academic-recognition',
      name: 'academic-recognition',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const AcademicRecognitionScreen(),
        );
      },
    ),
    GoRoute(
      path: '/academic-dashboard',
      name: 'academic-dashboard',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const AcademicDashboardScreen(),
        );
      },
    ),
    GoRoute(
      path: '/final-report',
      name: 'final-report',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const FinalReportScreen(),
        );
      },
    ),
    GoRoute(
      path: '/attendance',
      name: 'attendance',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const AttendanceScreen(),
        );
      },
    ),
    GoRoute(
      path: '/gradebook',
      name: 'gradebook',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const GradebookScreen(),
        );
      },
    ),
    GoRoute(
      path: '/saved-exams',
      name: 'saved-exams',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const SavedExamsScreen(),
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
      path: '/admin/financial-dashboard',
      name: 'financial-dashboard',
      builder: (context, state) => const FinancialDashboardScreen(),
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
