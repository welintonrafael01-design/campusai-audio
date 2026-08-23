import 'package:campusai_mobile/models/chat_message_model.dart';
import 'package:campusai_mobile/models/study_result.dart';
import 'package:campusai_mobile/services/chat_history_service.dart';
import 'package:campusai_mobile/services/academic_period_lock_service.dart';
import 'package:campusai_mobile/services/assessment_weight_service.dart';
import 'package:campusai_mobile/services/attendance_service.dart';
import 'package:campusai_mobile/services/course_service.dart';
import 'package:campusai_mobile/services/course_document_service.dart';
import 'package:campusai_mobile/services/gradebook_service.dart';
import 'package:campusai_mobile/services/educator_sync_service.dart';
import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:campusai_mobile/services/student_roster_service.dart';
import 'package:campusai_mobile/services/study_result_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    UserScopedStorage.debugSetUserScopeForTesting(null);
  });

  test('course and roster records are isolated by authenticated user scope',
      () async {
    UserScopedStorage.debugSetUserScopeForTesting('teacher_a');
    await CourseService.saveCourses(
      const [CourseRecord(id: 'course_a', name: 'Course A')],
    );
    await StudentRosterService.saveStudents(
      const [StudentRecord(id: 'student_a', name: 'Student A')],
    );

    UserScopedStorage.debugSetUserScopeForTesting('teacher_b');
    expect(await CourseService.getCourses(), isEmpty);
    expect(await StudentRosterService.getStudents(), isEmpty);

    await CourseService.saveCourses(
      const [CourseRecord(id: 'course_b', name: 'Course B')],
    );

    UserScopedStorage.debugSetUserScopeForTesting('teacher_a');
    expect((await CourseService.getCourses()).single.id, 'course_a');
    expect((await StudentRosterService.getStudents()).single.id, 'student_a');
  });

  test('chat history uses a distinct key for each document', () async {
    UserScopedStorage.debugSetUserScopeForTesting('student_a');
    final now = DateTime.utc(2026, 8, 17);

    await ChatHistoryService.saveMessages(
      documentId: 'document_a',
      messages: [
        ChatMessageModel(text: 'A', isUser: true, createdAt: now),
      ],
    );
    await ChatHistoryService.saveMessages(
      documentId: 'document_b',
      messages: [
        ChatMessageModel(text: 'B', isUser: true, createdAt: now),
      ],
    );

    expect(
        (await ChatHistoryService.loadMessages(documentId: 'document_a'))
            .single
            .text,
        'A');
    expect(
        (await ChatHistoryService.loadMessages(documentId: 'document_b'))
            .single
            .text,
        'B');
  });

  test('attendance, grades, weights, and period locks never cross Teachers',
      () async {
    UserScopedStorage.debugSetUserScopeForTesting('teacher_a');
    await AttendanceService.saveEntriesForDate(
      date: '2026-08-23',
      entries: const [
        AttendanceEntry(
          id: 'attendance-a',
          studentId: 'student-a',
          studentName: 'Student A',
          course: 'Course A',
          courseId: 'course-a',
          date: '2026-08-23',
          status: 'Presente',
        ),
      ],
    );
    await GradebookService.saveEntry(
      const GradebookEntry(
        id: 'grade-a',
        studentId: 'student-a',
        studentName: 'Student A',
        course: 'Course A',
        courseId: 'course-a',
        rubricTitle: 'Quiz',
        score: 90,
        maxScore: 100,
        createdAt: '2026-08-23T12:00:00Z',
      ),
    );
    await AssessmentWeightService.saveWeights(
      courseId: 'course-a',
      weights: const [AssessmentWeight(name: 'Quiz', weight: 100)],
    );
    await AcademicPeriodLockService.setClosed(
      courseId: 'course-a',
      closed: true,
    );

    UserScopedStorage.debugSetUserScopeForTesting('teacher_b');

    expect(await AttendanceService.getEntries(), isEmpty);
    expect(await GradebookService.getEntries(), isEmpty);
    expect(await AssessmentWeightService.getWeights('course-a'), isEmpty);
    expect(await AcademicPeriodLockService.isClosed('course-a'), isFalse);

    UserScopedStorage.debugSetUserScopeForTesting('teacher_a');

    expect((await AttendanceService.getEntries()).single.id, 'attendance-a');
    expect((await GradebookService.getEntries()).single.id, 'grade-a');
    expect(
      (await AssessmentWeightService.getWeights('course-a')).single.weight,
      100,
    );
    expect(await AcademicPeriodLockService.isClosed('course-a'), isTrue);
  });

  test('course program documents are isolated by Teacher scope', () async {
    UserScopedStorage.debugSetUserScopeForTesting('teacher_a');
    await CourseDocumentService.saveDocument(
      const CourseDocument(
        courseId: 'course-a',
        documentId: 'document-a',
        fileName: 'program-a.pdf',
        uploadedAt: '2026-08-23T12:00:00Z',
      ),
    );

    UserScopedStorage.debugSetUserScopeForTesting('teacher_b');
    expect(await CourseDocumentService.getDocuments(), isEmpty);

    UserScopedStorage.debugSetUserScopeForTesting('teacher_a');
    expect(
      (await CourseDocumentService.getDocuments()).single.documentId,
      'document-a',
    );
  });

  test('saved question banks are isolated by authenticated user scope',
      () async {
    UserScopedStorage.debugSetUserScopeForTesting('teacher_a');
    await StudyResultService.saveResult(
      StudyResult(
        documentId: 'document-a-question-bank',
        type: 'question_bank',
        content: '[{"question":"A?"}]',
        createdAt: '2026-08-23T00:00:00Z',
      ),
    );

    expect(
      (await EducatorSyncService.getLocalQuestionBanks()).single['documentId'],
      'document-a-question-bank',
    );

    UserScopedStorage.debugSetUserScopeForTesting('teacher_b');
    expect(await EducatorSyncService.getLocalQuestionBanks(), isEmpty);

    UserScopedStorage.debugSetUserScopeForTesting('teacher_a');
    await StudyResultService.deleteResult(
      documentId: 'document-a-question-bank',
      type: 'question_bank',
    );
    expect(await EducatorSyncService.getLocalQuestionBanks(), isEmpty);
  });
}
