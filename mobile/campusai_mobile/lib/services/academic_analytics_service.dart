import 'attendance_service.dart';
import 'assessment_weight_service.dart';
import 'gradebook_service.dart';
import 'student_roster_service.dart';

class StudentAcademicSummary {
  final String studentCode;
  final String studentName;
  final String courseId;
  final String courseName;
  final double average;
  final double attendanceRate;
  final int evaluations;
  final int attendedClasses;
  final int totalClasses;
  final bool approved;
  final bool hasGrades;
  final bool hasAttendance;
  final Map<String, double> assessmentScores;

  const StudentAcademicSummary({
    required this.studentCode,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.average,
    required this.attendanceRate,
    required this.evaluations,
    required this.attendedClasses,
    required this.totalClasses,
    required this.approved,
    required this.hasGrades,
    required this.hasAttendance,
    this.assessmentScores = const {},
  });

  Map<String, dynamic> toRow() {
    final row = <String, dynamic>{
      'student_code': studentCode,
      'student_name': studentName,
      'course': courseName,
    };

    for (final entry in assessmentScores.entries) {
      row[entry.key] = entry.value.toStringAsFixed(1);
    }

    row.addAll({
      'average': hasGrades ? average.toStringAsFixed(1) : 'Sin evaluar',
      'attendance_rate':
          hasAttendance ? attendanceRate.toStringAsFixed(1) : 'Sin registro',
      'evaluations': evaluations,
      'attended_classes': attendedClasses,
      'total_classes': totalClasses,
      'status': !hasGrades
          ? 'Sin evaluar'
          : (approved ? 'Aprobado' : 'Reprobado'),
    });

    return row;
  }
}

class AcademicAnalyticsService {

  static String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúñü ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _sameCourse({
    required String targetCourseId,
    required String targetCourseName,
    required String entryCourseId,
    required String entryCourseName,
  }) {
    final cleanTargetId = targetCourseId.trim();
    final cleanEntryId = entryCourseId.trim();

    if (cleanTargetId.isNotEmpty &&
        cleanEntryId.isNotEmpty &&
        cleanTargetId == cleanEntryId) {
      return true;
    }

    final targetName = _normalizeText(targetCourseName);
    final entryName = _normalizeText(entryCourseName);

    if (targetName.isEmpty || entryName.isEmpty) return false;

    return targetName == entryName ||
        targetName.contains(entryName) ||
        entryName.contains(targetName);
  }

  static bool _sameStudent({
    required String studentId,
    required String studentCode,
    required String studentName,
    required String entryStudentId,
    required String entryStudentCode,
    required String entryStudentName,
  }) {
    final cleanStudentId = studentId.toLowerCase().trim();
    final cleanStudentCode = studentCode.toLowerCase().trim();
    final cleanEntryStudentId = entryStudentId.toLowerCase().trim();
    final cleanEntryStudentCode = entryStudentCode.toLowerCase().trim();

    if (cleanStudentCode.isNotEmpty &&
        cleanEntryStudentCode.isNotEmpty &&
        cleanStudentCode == cleanEntryStudentCode) {
      return true;
    }

    if (cleanStudentId.isNotEmpty &&
        cleanEntryStudentId.isNotEmpty &&
        cleanStudentId == cleanEntryStudentId) {
      return true;
    }

    return _normalizeText(studentName) == _normalizeText(entryStudentName);
  }

  static Future<List<StudentAcademicSummary>> buildFinalReport({
    required String courseId,
    required String courseName,
    double passingScore = 70,
  }) async {
    final students = await StudentRosterService.getStudents();
    final grades = await GradebookService.getEntries();
    final attendance = await AttendanceService.getEntries();
    final weights = await AssessmentWeightService.getWeights(courseId);

    final courseStudents = students.where((student) {
      return _sameCourse(
        targetCourseId: courseId,
        targetCourseName: courseName,
        entryCourseId: student.courseId,
        entryCourseName: student.course,
      );
    }).toList();

    final summaries = <StudentAcademicSummary>[];

    for (final student in courseStudents) {
      final studentCode = student.studentCode.isNotEmpty
          ? student.studentCode
          : student.id;

      final studentGrades = grades.where((entry) {
        final sameCourse = _sameCourse(
          targetCourseId: courseId,
          targetCourseName: courseName,
          entryCourseId: entry.courseId,
          entryCourseName: entry.course,
        );

        final sameStudent = _sameStudent(
          studentId: student.id,
          studentCode: studentCode,
          studentName: student.name,
          entryStudentId: entry.studentId,
          entryStudentCode: entry.studentCode,
          entryStudentName: entry.studentName,
        );

        return sameCourse && sameStudent;
      }).toList();

      final percentages = studentGrades
          .where((entry) => entry.maxScore > 0)
          .map((entry) => (entry.score / entry.maxScore) * 100)
          .toList();

      final hasGrades = percentages.isNotEmpty;

      final average = hasGrades
          ? AssessmentWeightService.weightedAverage(
              grades: studentGrades,
              weights: weights,
              percentageBuilder: (entry) =>
                  (entry.score / entry.maxScore) * 100,
              assessmentNameBuilder: (entry) => entry.rubricTitle,
            )
          : 0.0;

      final studentAttendance = attendance.where((entry) {
        final sameCourse = _sameCourse(
          targetCourseId: courseId,
          targetCourseName: courseName,
          entryCourseId: entry.courseId,
          entryCourseName: entry.course,
        );

        final sameStudent = _sameStudent(
          studentId: student.id,
          studentCode: studentCode,
          studentName: student.name,
          entryStudentId: entry.studentId,
          entryStudentCode: '',
          entryStudentName: entry.studentName,
        );

        return sameCourse && sameStudent;
      }).toList();

      final totalClasses = studentAttendance.length;

      final attendedClasses = studentAttendance.where((entry) {
        final status = entry.status.toLowerCase().trim();
        return status == 'presente' ||
            status == 'tardanza' ||
            status == 'excusa';
      }).length;

      final hasAttendance = totalClasses > 0;

      final attendanceRate = hasAttendance
          ? (attendedClasses / totalClasses) * 100
          : 0.0;

      final assessmentScores = <String, double>{};

      for (final grade in studentGrades) {
        if (grade.maxScore <= 0) continue;

        final assessmentName = grade.rubricTitle.trim().isEmpty
            ? 'Evaluación'
            : grade.rubricTitle.trim();

        assessmentScores[assessmentName] =
            (grade.score / grade.maxScore) * 100;
      }

      summaries.add(
        StudentAcademicSummary(
          studentCode: studentCode,
          studentName: student.name,
          courseId: courseId,
          courseName: courseName,
          average: average,
          attendanceRate: attendanceRate,
          evaluations: studentGrades.length,
          attendedClasses: attendedClasses,
          totalClasses: totalClasses,
          approved: hasGrades && average >= passingScore,
          hasGrades: hasGrades,
          hasAttendance: hasAttendance,
          assessmentScores: assessmentScores,
        ),
      );
    }

    summaries.sort((a, b) => a.studentName.compareTo(b.studentName));

    return summaries;
  }
}
