import 'dart:convert';

import 'package:campusai_mobile/config/app_plans.dart';
import 'package:campusai_mobile/controllers/document_upload_controller.dart';
import 'package:campusai_mobile/models/audiobook_history.dart';
import 'package:campusai_mobile/models/chat_message_model.dart';
import 'package:campusai_mobile/models/document_history.dart';
import 'package:campusai_mobile/models/study_result.dart';
import 'package:campusai_mobile/router/app_router.dart';
import 'package:campusai_mobile/services/access_control_service.dart';
import 'package:campusai_mobile/services/api_service.dart';
import 'package:campusai_mobile/services/audiobook_library_service.dart';
import 'package:campusai_mobile/services/auth_service.dart';
import 'package:campusai_mobile/services/chat_history_service.dart';
import 'package:campusai_mobile/services/cloud_api_service.dart';
import 'package:campusai_mobile/services/course_service.dart';
import 'package:campusai_mobile/services/educator_sync_service.dart';
import 'package:campusai_mobile/services/history_service.dart';
import 'package:campusai_mobile/services/plan_guard_service.dart';
import 'package:campusai_mobile/services/student_roster_service.dart';
import 'package:campusai_mobile/services/study_result_service.dart';
import 'package:campusai_mobile/services/subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'e2e_real_fixture.dart';
import 'e2e_test_config.dart';
import 'e2e_test_harness.dart';

class FullRealE2eJourney {
  FullRealE2eJourney(this.tester);

  final WidgetTester tester;
  final List<String> blockedExternalConfig = [];

  String studentADocumentId = '';
  String studentAChatId = '';
  String teacherCourseId = '';
  String teacherStudentId = '';
  String teacherDocumentId = '';
  String? _externalAiReason;

  static const _studentFileName = 'QA_E2E_student_fixture.pdf';
  static const _teacherFileName = 'QA_E2E_teacher_fixture.pdf';
  static const _fixtureText =
      'Los ecosistemas conectan productores, consumidores y descomponedores. '
      'La energía fluye y los nutrientes se reciclan en el ambiente.';

  Future<void> run() async {
    await pumpStudyBookApp(tester, useMockLocalStorage: false);
    await _logoutToAuth();

    await _runStudentA();
    await _runStudentB();
    await _runTeacher();
    await _runGuest();

    _manualGate(
      kIsWeb ? 'WEB_FILE_PICKER' : 'NATIVE_ANDROID_FILE_PICKER',
      'visual behavior',
    );
    _manualGate('AUDIOBOOK_SOUND', 'acoustic quality');
    _manualGate('VOICE_TUTOR_MICROPHONE', 'physical microphone quality');
    if (blockedExternalConfig.isNotEmpty) {
      _result('CORE', 'BLOCKED_EXTERNAL_CONFIG');
    } else {
      _result('CORE', 'PASS');
    }

    if (kIsWeb) {
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );
      await tester.pump();
    }
  }

  Future<void> runTeacherDiagnostic() async {
    await pumpStudyBookApp(tester, useMockLocalStorage: false);
    await _logoutToAuth();
    await _runTeacher();
    await _runGuest();
    _result('TEACHER_DIAGNOSTIC', 'PASS');
  }

  Future<void> _runStudentA() async {
    await _loginThroughUi(
      email: E2eTestConfig.studentAEmail,
      password: E2eTestConfig.studentAPassword,
      expectedRole: StudyBookRole.student,
      expectedPlan: CampusPlan.student,
    );
    _result('STUDENT_A_AUTH', 'PASS');

    await _assertStudentRoutesDenied();
    await _cleanupHarnessDocuments(_studentFileName);

    final upload = await _uploadFixture(_studentFileName);
    studentADocumentId = upload.documentId;
    _artifact('student_a_document_id', studentADocumentId);
    _result('HOME', 'PASS');
    _result('UPLOAD_PIPELINE', 'PASS');

    await _generateStudentArtifacts(upload);
    await _assertLibraryAndLearning(upload);
    if (kIsWeb) {
      await _assertWebRuntimePersistence(upload);
      await _assertWebResponsiveSmoke();
    }
    await _assertAccountAndRestore(upload);

    await _logoutToAuth();
  }

  Future<void> _runStudentB() async {
    await _loginThroughUi(
      email: E2eTestConfig.studentBEmail,
      password: E2eTestConfig.studentBPassword,
      expectedRole: StudyBookRole.student,
      expectedPlan: CampusPlan.student,
    );
    _result('STUDENT_B_AUTH', 'PASS');

    final documents = await CloudApiService.getLibraryDocuments();
    expect(_containsDocument(documents, studentADocumentId), isFalse);

    final results = await CloudApiService.getStudyResults();
    expect(_containsDocument(results, studentADocumentId), isFalse);

    final chats = await CloudApiService.getChats();
    expect(_containsDocument(chats, studentADocumentId), isFalse);

    final audiobooks = await CloudApiService.getAudiobooks();
    expect(_containsDocument(audiobooks, studentADocumentId), isFalse);

    final localHistory = await HistoryService.getHistory();
    expect(
      localHistory.any((item) => item.documentId == studentADocumentId),
      isFalse,
    );

    final localFlashcards =
        await StudyResultService.getResultsByType('flashcards');
    expect(
      localFlashcards.any((item) => item.documentId == studentADocumentId),
      isFalse,
    );

    final ownershipStatus = await _postStatus(
      '/documents/chat/$studentADocumentId',
      query: const {'question': 'QA ownership check'},
    );
    expect(ownershipStatus, anyOf(403, 404));

    final hiddenArtifact = await CloudApiService.getStudyResult(
      documentId: studentADocumentId,
      type: 'flashcards',
    );
    expect(hiddenArtifact, isNull);

    await _assertStudentRoutesDenied();
    _result('CLOUD_MULTIUSER_ISOLATION', 'PASS');
    _result('DIRECT_OWNERSHIP_ATTACK', 'PASS');
    if (kIsWeb) {
      _result('BROWSER_CACHE_ISOLATION', 'PASS');
    }

    await _logoutToAuth();
  }

  Future<void> _runTeacher() async {
    await _loginThroughUi(
      email: E2eTestConfig.teacherEmail,
      password: E2eTestConfig.teacherPassword,
      expectedRole: StudyBookRole.teacher,
      expectedPlan: CampusPlan.teacher,
    );
    _result('TEACHER_AUTH', 'PASS');

    await _go('/admin');
    expect(_currentPath, '/dashboard');

    await _createTeacherFixture();
    await _go('/teacher');
    expect(_currentPath, '/teacher');
    await _scrollUntilText('QA E2E Course');

    await _go('/students');
    expect(_currentPath, '/students');
    await _scrollUntilText('QA E2E Student');

    await _cleanupHarnessDocuments(_teacherFileName);
    final upload = await _uploadFixture(_teacherFileName);
    teacherDocumentId = upload.documentId;
    _artifact('teacher_document_id', teacherDocumentId);

    final teachingPlan = await _runAi<Map<String, dynamic>>(
      'TEACHER_STUDIO',
      () => ApiService.generateTeachingPlanByDocumentId(
        documentId: teacherDocumentId,
        weeks: 1,
      ),
    );
    if (teachingPlan != null) {
      expect(_hasContent(teachingPlan['teaching_plan']), isTrue);
      await _saveArtifact(
        documentId: teacherDocumentId,
        type: 'teaching_plan',
        payload: teachingPlan['teaching_plan'],
      );
      _result('TEACHER_STUDIO', 'PASS');
    }

    await _logoutToAuth();
  }

  Future<void> _runGuest() async {
    await _go('/library');
    expect(_currentPath, '/auth');
    expect(AuthService.isLoggedIn, isFalse);
    _result('GUEST_PRIVATE_ROUTES', 'PASS');
  }

  Future<void> _loginThroughUi({
    required String email,
    required String password,
    required StudyBookRole expectedRole,
    required CampusPlan expectedPlan,
  }) async {
    await _go('/auth');
    expect(find.byType(TextField), findsAtLeastNWidgets(2));
    await AuthService.signIn(email: email, password: password);
    await EducatorSyncService.pullRemoteIntoLocalIfAvailable();
    await _pumpUntil(() => AuthService.isLoggedIn);

    final user = AuthService.currentUser;
    expect(user, isNotNull);
    expect(user!.id.trim(), isNotEmpty);

    final plan = await const SubscriptionService().syncCurrentUserPlan();
    final subscription = await ApiService.getSubscription();
    final status = subscription['subscription_status']?.toString();

    expect(const AccessControlService().role, expectedRole);
    expect(plan, expectedPlan);
    expect(status, 'active');
    expect(const PlanGuardService().currentPlan, expectedPlan);
    expect(const AccessControlService().isAdmin, isFalse);

    await _go('/dashboard');
    expect(_currentPath, '/dashboard');
  }

  Future<void> _logoutToAuth() async {
    if (AuthService.isLoggedIn) {
      await AuthService.signOut();
    }
    await _go('/auth');
    expect(AuthService.isLoggedIn, isFalse);
  }

  Future<void> _assertStudentRoutesDenied() async {
    await _go('/teacher');
    expect(_currentPath, '/dashboard');

    await _go('/admin');
    expect(_currentPath, '/dashboard');

    final teacherApiStatus = await _getStatus('/educator/snapshot');
    expect(teacherApiStatus, 403);
    _result('STUDENT_TEACHER_ROUTE', 'PASS');
    _result('STUDENT_TEACHER_BACKEND', 'PASS');
    _result('ADMIN_ACCESS', 'PASS');
  }

  Future<DocumentHistory> _uploadFixture(String fileName) async {
    final controller = DocumentUploadController(
      picker: () async => buildQaPdfFixture(name: fileName),
    );
    final result = await controller.pickAndUploadPdf();
    expect(result.isSuccess, isTrue, reason: result.message);

    final data = result.data;
    final document = DocumentHistory(
      documentId: data['document_id']?.toString() ?? '',
      fileName: data['file_name']?.toString() ??
          data['filename']?.toString() ??
          fileName,
      summary: data['ai_summary']?.toString() ?? '',
      audioUrl: data['audio_url']?.toString() ?? '',
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    expect(document.isValid, isTrue);
    expect(document.summary.trim(), isNotEmpty);

    await HistoryService.saveDocument(document);

    Map<dynamic, dynamic>? cloudDocument;
    for (var attempt = 0; attempt < 6 && cloudDocument == null; attempt++) {
      final cloudDocuments = await CloudApiService.getLibraryDocuments();
      for (final item in cloudDocuments.whereType<Map>()) {
        if (item['document_id']?.toString() == document.documentId) {
          cloudDocument = item;
          break;
        }
      }
      if (cloudDocument == null) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    expect(
      cloudDocument,
      isNotNull,
      reason: 'El upload real no apareció en la Biblioteca Cloud.',
    );
    final persistedDocument = cloudDocument!;
    expect(
      persistedDocument['user_id']?.toString(),
      AuthService.currentUser!.id,
    );
    expect(
      (persistedDocument['filename'] ?? persistedDocument['document_name'])
          ?.toString(),
      fileName,
    );
    expect(
      persistedDocument['summary']?.toString().trim(),
      isNotEmpty,
    );
    _result('SUMMARY', 'PASS');
    return document;
  }

  Future<void> _generateStudentArtifacts(DocumentHistory document) async {
    final chat = await _runAi<Map<String, dynamic>>(
      'CHAT',
      () => ApiService.chatWithDocumentId(
        documentId: document.documentId,
        question: '¿Cuál es la función de los descomponedores?',
      ),
    );
    if (chat != null) {
      final answer = chat['answer']?.toString().trim() ?? '';
      expect(answer, isNotEmpty);
      final cloudChat = await CloudApiService.createChat(
        documentId: document.documentId,
        title: 'QA E2E Chat',
      );
      studentAChatId = cloudChat['id']?.toString() ?? '';
      expect(studentAChatId, isNotEmpty);
      await CloudApiService.saveMessage(
        chatId: studentAChatId,
        role: 'user',
        content: '¿Cuál es la función de los descomponedores?',
      );
      await CloudApiService.saveMessage(
        chatId: studentAChatId,
        role: 'assistant',
        content: answer,
      );
      await ChatHistoryService.saveMessages(
        documentId: document.documentId,
        messages: [
          ChatMessageModel(
            text: '¿Cuál es la función de los descomponedores?',
            isUser: true,
            createdAt: DateTime.now().toUtc(),
          ),
          ChatMessageModel(
            text: answer,
            isUser: false,
            createdAt: DateTime.now().toUtc(),
          ),
        ],
      );
      _artifact('student_a_chat_id', studentAChatId);
      _result('CHAT', 'PASS');
    }

    final flashcards = await _runAi<Map<String, dynamic>>(
      'FLASHCARDS',
      () => ApiService.generateFlashcardsByDocumentId(
        documentId: document.documentId,
        numberOfCards: 3,
      ),
    );
    if (flashcards != null) {
      expect(_hasContent(flashcards['flashcards']), isTrue);
      await _saveArtifact(
        documentId: document.documentId,
        type: 'flashcards',
        payload: flashcards['flashcards'],
      );
      _result('FLASHCARDS', 'PASS');
    }

    final quiz = await _runAi<Map<String, dynamic>>(
      'QUIZ',
      () => ApiService.generateExamByDocumentId(
        documentId: document.documentId,
        numberOfQuestions: 3,
        examType: 'Quiz de selección múltiple',
        difficulty: 'Básico',
        examTopic: 'Ecosistemas',
      ),
    );
    if (quiz != null) {
      expect(_hasContent(quiz['questions']), isTrue);
      await _saveArtifact(
        documentId: document.documentId,
        type: 'quiz',
        payload: quiz['questions'],
      );
      _result('QUIZ', 'PASS');
    }

    final questionBank = await _runAi<Map<String, dynamic>>(
      'QUESTION_BANK',
      () => ApiService.generateQuestionBankByDocumentId(
        documentId: document.documentId,
        numberOfQuestions: 5,
        programTopic: 'Ecosistemas',
        learningObjective: 'Explicar relaciones de energía y materia',
        competency: 'Analizar cambios ambientales',
        bloomLevel: 'Analizar',
      ),
    );
    if (questionBank != null) {
      expect(_hasContent(questionBank['questions']), isTrue);
      await _saveArtifact(
        documentId: document.documentId,
        type: 'question_bank',
        payload: questionBank['questions'],
      );
      _result('QUESTION_BANK', 'PASS');
    }

    final exam = await _runAi<Map<String, dynamic>>(
      'EXAM',
      () => ApiService.generateExamByDocumentId(
        documentId: document.documentId,
        numberOfQuestions: 2,
        examTopic: 'Ecosistemas',
        examObjective: 'Comprobar comprensión del flujo de energía',
      ),
    );
    if (exam != null) {
      expect(_hasContent(exam['questions']), isTrue);
      await _saveArtifact(
        documentId: document.documentId,
        type: 'exam',
        payload: exam['questions'],
      );
      _result('EXAM', 'PASS');
    }

    final audiobook = await _runAi<Map<String, dynamic>>(
      'AUDIOBOOK',
      () => ApiService.generateAudioBookFromText(
        title: 'QA E2E Ecosistemas',
        text: _fixtureText,
        sourceType: 'document',
        sourceDocumentId: document.documentId,
      ),
    );
    if (audiobook != null) {
      final payload = audiobook['audiobook'];
      expect(payload, isA<Map>());
      final audiobookMap = Map<String, dynamic>.from(payload as Map);
      final chapters = (audiobookMap['chapters'] as List?)
              ?.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList() ??
          [];
      expect(chapters, isNotEmpty);
      final audiobookId = '${document.documentId}_audiobook';
      await CloudApiService.saveAudiobook(
        documentId: audiobookId,
        fileName: 'QA E2E Ecosistemas',
        chapters: chapters,
      );
      await const AudiobookLibraryService().saveAudiobook(
        AudiobookHistory(
          documentId: audiobookId,
          fileName: 'QA E2E Ecosistemas',
          chapters: chapters,
          createdAt: DateTime.now().toUtc().toIso8601String(),
        ),
      );
      _artifact('student_a_audiobook_id', audiobookId);
      _result('AUDIOBOOK', 'PASS');
    }

    final voiceTutor = await _runAi<Map<String, dynamic>>(
      'VOICE_TUTOR',
      () => ApiService.askAiCoach(
        message: 'Resume en una frase qué es un ecosistema.',
        mode: 'study',
        context: {'document_id': document.documentId},
      ),
    );
    if (voiceTutor != null) {
      expect(_hasContent(voiceTutor), isTrue);
      _result('VOICE_TUTOR_TEXT', 'PASS');
    }
  }

  Future<void> _assertLibraryAndLearning(DocumentHistory document) async {
    final cloudDocuments = await CloudApiService.getLibraryDocuments();
    expect(_containsDocument(cloudDocuments, document.documentId), isTrue);

    final artifactTypes = ['flashcards', 'quiz', 'question_bank', 'exam'];
    for (final type in artifactTypes) {
      if (_externalAiReason != null) continue;
      final result = await CloudApiService.getStudyResult(
        documentId: document.documentId,
        type: type,
      );
      expect(result, isNotNull, reason: 'Missing persisted $type');
    }

    await _go('/library');
    expect(_currentPath, '/library');
    await _pumpUntilText(document.fileName);
    _result('LIBRARY', 'PASS');

    await _go('/learning');
    expect(_currentPath, '/learning');
    expect(
      textAny(['Aprendizaje', 'Continuar', 'Progreso', 'Booky']),
      findsWidgets,
    );
    _result('LEARNING', 'PASS');
  }

  Future<void> _assertAccountAndRestore(DocumentHistory document) async {
    await _go('/account');
    expect(_currentPath, '/account');
    final subscription = await ApiService.getSubscription();
    expect(subscription['plan']?.toString(), 'student');
    expect(subscription['subscription_status']?.toString(), 'active');
    _result('ACCOUNT', 'PASS');

    await _logoutToAuth();
    await _go('/library');
    expect(_currentPath, '/auth');

    await _loginThroughUi(
      email: E2eTestConfig.studentAEmail,
      password: E2eTestConfig.studentAPassword,
      expectedRole: StudyBookRole.student,
      expectedPlan: CampusPlan.student,
    );

    final restoredDocuments = await CloudApiService.getLibraryDocuments();
    expect(_containsDocument(restoredDocuments, document.documentId), isTrue);
    final restoredLocal = await HistoryService.getHistory();
    expect(
      restoredLocal.any((item) => item.documentId == document.documentId),
      isTrue,
    );
    final restoredDocument = restoredDocuments.whereType<Map>().firstWhere(
          (item) => item['document_id']?.toString() == document.documentId,
        );
    expect(restoredDocument['summary']?.toString().trim(), isNotEmpty);
    _result('LOGOUT_LOGIN_RESTORE', 'PASS');
  }

  Future<void> _assertWebRuntimePersistence(DocumentHistory document) async {
    final userId = AuthService.currentUser!.id;

    await _go('/library');
    await _pumpUntilText(document.fileName);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpStudyBookApp(tester, useMockLocalStorage: false);

    expect(AuthService.currentUser?.id, userId);
    final restoredPlan =
        await const SubscriptionService().syncCurrentUserPlan();
    expect(restoredPlan, CampusPlan.student);
    expect(const AccessControlService().role, StudyBookRole.student);
    expect(const AccessControlService().hasTeacherTools, isFalse);

    await _go('/library');
    await _pumpUntilText(document.fileName);
    final restored = await CloudApiService.getStudyResult(
      documentId: document.documentId,
      type: 'flashcards',
    );
    expect(restored, isNotNull);
    _result('WEB_SESSION_STORAGE', 'PASS');
    _result('WEB_APP_RESTART', 'PASS');
  }

  Future<void> _assertWebResponsiveSmoke() async {
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;

    try {
      tester.view.devicePixelRatio = 1;
      for (final size in const [Size(1440, 900), Size(390, 844)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();

        for (final route in const ['/dashboard', '/library', '/account']) {
          await _go(route);
          expect(_currentPath, route);
        }
      }
      _result('RESPONSIVE_WEB_SMOKE', 'PASS');
    } finally {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
      await tester.pumpAndSettle();
    }
  }

  Future<void> _createTeacherFixture() async {
    final userId = AuthService.currentUser!.id.replaceAll('-', '');
    final suffix = userId.substring(0, 8);
    teacherCourseId = 'qa_e2e_${suffix}_course';
    teacherStudentId = 'qa_e2e_${suffix}_student';

    await CourseService.addCourse(
      CourseRecord(
        id: teacherCourseId,
        name: 'QA E2E Course',
        code: 'QA101',
        section: 'A',
        period: 'RC1',
      ),
    );
    await StudentRosterService.addStudent(
      StudentRecord(
        id: teacherStudentId,
        name: 'QA E2E Student',
        course: 'QA E2E Course',
        courseId: teacherCourseId,
        email: 'qa.e2e.student@example.invalid',
        studentCode: 'QA-E2E-001',
      ),
    );

    await EducatorSyncService.pushLocalSnapshot();
    final snapshot = await EducatorSyncService.getSnapshot();
    final courses = snapshot['courses'] as List? ?? [];
    final students = snapshot['students'] as List? ?? [];
    expect(_containsId(courses, teacherCourseId), isTrue);
    expect(_containsId(students, teacherStudentId), isTrue);

    _artifact('teacher_course_id', teacherCourseId);
    _artifact('teacher_student_id', teacherStudentId);
  }

  Future<void> _saveArtifact({
    required String documentId,
    required String type,
    required dynamic payload,
  }) async {
    final content = jsonEncode(payload);
    expect(content.trim(), isNotEmpty);
    final result = StudyResult(
      documentId: documentId,
      type: type,
      content: content,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    await StudyResultService.saveResult(result);
    await CloudApiService.saveStudyResult(
      documentId: documentId,
      type: type,
      content: content,
    );
  }

  Future<void> _cleanupHarnessDocuments(String fileName) async {
    final documents = await CloudApiService.getLibraryDocuments();
    final matches = documents.whereType<Map>().where((item) {
      final name = (item['filename'] ?? item['document_name'])?.toString();
      return name == fileName;
    }).toList();

    for (final document in matches) {
      final documentId = document['document_id']?.toString() ?? '';
      if (documentId.isEmpty) continue;

      for (final type in const [
        'summary',
        'flashcards',
        'quiz',
        'question_bank',
        'exam',
        'audiobook',
        'teaching_plan',
      ]) {
        try {
          await CloudApiService.deleteStudyResult(
            documentId: documentId,
            type: type,
          );
        } catch (_) {}
      }

      final chats = await CloudApiService.getChats(documentId: documentId);
      for (final chat in chats.whereType<Map>()) {
        final chatId = chat['id']?.toString() ?? '';
        if (chatId.isNotEmpty) {
          await CloudApiService.deleteChat(chatId: chatId);
        }
      }

      try {
        await CloudApiService.deleteAudiobook(
          documentId: '${documentId}_audiobook',
        );
      } catch (_) {}
      await CloudApiService.deleteDocument(documentId: documentId);
    }

    final localDocuments = await HistoryService.getHistory();
    for (var index = localDocuments.length - 1; index >= 0; index--) {
      if (localDocuments[index].fileName == fileName) {
        await HistoryService.deleteDocument(index);
      }
    }
  }

  Future<T?> _runAi<T>(String step, Future<T> Function() action) async {
    if (_externalAiReason != null) {
      blockedExternalConfig.add(step);
      _result(step, 'BLOCKED_EXTERNAL_CONFIG');
      return null;
    }

    try {
      return await action();
    } catch (error) {
      if (_isExternalAiFailure(error)) {
        _externalAiReason = _classifyExternalAiFailure(error);
        blockedExternalConfig.add(step);
        _result(step, 'BLOCKED_EXTERNAL_CONFIG');
        debugPrint('E2E_BLOCKED dependency=$_externalAiReason step=$step');
        return null;
      }
      rethrow;
    }
  }

  bool _isExternalAiFailure(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('quota') ||
        text.contains('rate limit') ||
        text.contains('rate_limit') ||
        text.contains('provider') ||
        text.contains('api key') ||
        text.contains('openai') ||
        text.contains('429') ||
        text.contains('502') ||
        text.contains('503') ||
        text.contains('unavailable');
  }

  String _classifyExternalAiFailure(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('quota')) return 'ai_quota';
    if (text.contains('rate')) return 'ai_rate_limit';
    if (text.contains('api key')) return 'ai_missing_key';
    return 'ai_provider_unavailable';
  }

  Future<int> _getStatus(String path) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}$path'),
      headers: AuthService.authHeaders,
    );
    return response.statusCode;
  }

  Future<int> _postStatus(
    String path, {
    Map<String, String> query = const {},
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}$path').replace(
      queryParameters: query,
    );
    final response = await http.post(uri, headers: AuthService.authHeaders);
    return response.statusCode;
  }

  Future<void> _go(String path) async {
    appRouter.go(path);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> _pumpUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 40),
  }) async {
    final end = DateTime.now().add(timeout);
    while (!condition() && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(condition(), isTrue);
  }

  Future<void> _pumpUntilText(String value) {
    return _pumpUntil(
      () => find.textContaining(value).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 30),
    );
  }

  Future<void> _scrollUntilText(String value) async {
    final target = find.textContaining(value);
    final verticalScrollable = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .hitTestable()
        .last;
    await tester.scrollUntilVisible(
      target,
      360,
      scrollable: verticalScrollable,
      maxScrolls: 12,
    );
    expect(target, findsWidgets);
  }

  String get _currentPath => appRouter.routeInformationProvider.value.uri.path;

  bool _containsDocument(List<dynamic> items, String documentId) {
    return items.whereType<Map>().any(
          (item) => item['document_id']?.toString() == documentId,
        );
  }

  bool _containsId(List<dynamic> items, String id) {
    return items.whereType<Map>().any(
          (item) => item['id']?.toString() == id,
        );
  }

  bool _hasContent(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  void _artifact(String key, String value) {
    final safeValue = value.replaceAll(RegExp(r'[^a-zA-Z0-9_.:-]'), '_');
    debugPrint('E2E_ARTIFACT $key=$safeValue');
  }

  void _result(String step, String status) {
    debugPrint('E2E_RESULT $step=$status');
  }

  void _manualGate(String step, String reason) {
    debugPrint('E2E_MANUAL_GATE $step=${reason.replaceAll(' ', '_')}');
  }
}
