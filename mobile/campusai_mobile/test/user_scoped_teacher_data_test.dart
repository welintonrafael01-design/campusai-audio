import 'package:campusai_mobile/models/chat_message_model.dart';
import 'package:campusai_mobile/services/chat_history_service.dart';
import 'package:campusai_mobile/services/course_service.dart';
import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:campusai_mobile/services/student_roster_service.dart';
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
}
