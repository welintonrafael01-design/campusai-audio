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
      isConfiguredValue(studentAEmail) && isConfiguredValue(studentAPassword);

  static bool get hasStudentB =>
      isConfiguredValue(studentBEmail) && isConfiguredValue(studentBPassword);

  static bool get hasTeacher =>
      isConfiguredValue(teacherEmail) && isConfiguredValue(teacherPassword);

  static bool get hasTwoStudents => hasStudentA && hasStudentB;

  static bool isConfiguredValue(String value) {
    final normalized = value.trim();
    return normalized.isNotEmpty && !normalized.startsWith('<');
  }
}
