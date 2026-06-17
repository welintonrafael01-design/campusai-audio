import 'attendance_service.dart';
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
  });

  Map<String, dynamic> toRow() => {
        'student_code': studentCode,
        'student_name': studentName,
        'course': courseName,
        'average': average.toStringAsFixed(1),
        'attendance_rate': attendanceRate.toStringAsFixed(1),
        'evaluations': evaluations,
        'attended_classes': attendedClasses,
        'total_classes': totalClasses,
        'status': approved ? 'Aprobado' : 'Reprobado',
      };
}

class AcademicAnalyticsService {
  static Future<List<StudentAcademicSummary>> buildFinalReport({
    required String courseId,
    required String courseName,
    double passingScore = 70,
  }) async {
    final students = await StudentRosterService.getStudents();
    final grades = await GradebookService.getEntries();
    final attendance = await AttendanceService.getEntries();

    final courseStudents = students.where((student) {
      if (student.courseId.isNotEmpty) {
        return student.courseId == courseId;
      }

      return student.course.toLowerCase().trim() ==
          courseName.toLowerCase().trim();
    }).toList();

    final summaries = <StudentAcademicSummary>[];

    for (final student in courseStudents) {
      final studentCode = student.studentCode.isNotEmpty
          ? student.studentCode
          : student.id;

      final studentGrades = grades.where((entry) {
        final sameCourse = entry.courseId.isNotEmpty
            ? entry.courseId == courseId
            : entry.course.toLowerCase().trim() ==
                courseName.toLowerCase().trim();

        final sameStudentByCode = studentCode.isNotEmpty &&
            entry.studentCode.toLowerCase().trim() ==
                studentCode.toLowerCase().trim();

        final sameStudentByName = entry.studentName.toLowerCase().trim() ==
            student.name.toLowerCase().trim();

        return sameCourse && (sameStudentByCode || sameStudentByName);
      }).toList();

      final percentages = studentGrades
          .where((entry) => entry.maxScore > 0)
          .map((entry) => (entry.score / entry.maxScore) * 100)
          .toList();

      final average = percentages.isEmpty
          ? 0.0
          : percentages.reduce((a, b) => a + b) / percentages.length;

      final studentAttendance = attendance.where((entry) {
        final sameCourse = entry.courseId.isNotEmpty
            ? entry.courseId == courseId
            : entry.course.toLowerCase().trim() ==
                courseName.toLowerCase().trim();

        final sameStudentById = entry.studentId.toLowerCase().trim() ==
            student.id.toLowerCase().trim();

        final sameStudentByName = entry.studentName.toLowerCase().trim() ==
            student.name.toLowerCase().trim();

        return sameCourse && (sameStudentById || sameStudentByName);
      }).toList();

      final totalClasses = studentAttendance.length;

      final attendedClasses = studentAttendance.where((entry) {
        final status = entry.status.toLowerCase().trim();
        return status == 'presente' ||
            status == 'tardanza' ||
            status == 'excusa';
      }).length;

      final attendanceRate = totalClasses == 0
          ? 0.0
          : (attendedClasses / totalClasses) * 100;

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
          approved: average >= passingScore,
        ),
      );
    }

    summaries.sort((a, b) => a.studentName.compareTo(b.studentName));

    return summaries;
  }
}
