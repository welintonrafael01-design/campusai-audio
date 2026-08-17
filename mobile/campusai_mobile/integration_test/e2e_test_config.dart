class E2eTestConfig {
  const E2eTestConfig._();

  static const studentAEmail = String.fromEnvironment('QA_STUDENT_A_EMAIL');
  static const studentAPassword =
      String.fromEnvironment('QA_STUDENT_A_PASSWORD');
  static const studentBEmail = String.fromEnvironment('QA_STUDENT_B_EMAIL');
  static const studentBPassword =
      String.fromEnvironment('QA_STUDENT_B_PASSWORD');
  static const teacherEmail = String.fromEnvironment('QA_TEACHER_EMAIL');
  static const teacherPassword = String.fromEnvironment('QA_TEACHER_PASSWORD');
  static const backendUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static bool get hasStudentA =>
      studentAEmail.trim().isNotEmpty && studentAPassword.trim().isNotEmpty;

  static bool get hasStudentB =>
      studentBEmail.trim().isNotEmpty && studentBPassword.trim().isNotEmpty;

  static bool get hasTeacher =>
      teacherEmail.trim().isNotEmpty && teacherPassword.trim().isNotEmpty;

  static bool get hasTwoStudents => hasStudentA && hasStudentB;
}
