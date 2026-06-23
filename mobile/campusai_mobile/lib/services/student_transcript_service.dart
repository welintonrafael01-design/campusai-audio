import 'academic_analytics_service.dart';
import 'course_service.dart';
import 'student_roster_service.dart';

class TranscriptCourseRow {
  final String courseId;
  final String courseName;
  final double average;
  final double attendanceRate;
  final bool hasGrades;
  final bool hasAttendance;
  final bool approved;
  final int evaluations;

  const TranscriptCourseRow({
    required this.courseId,
    required this.courseName,
    required this.average,
    required this.attendanceRate,
    required this.hasGrades,
    required this.hasAttendance,
    required this.approved,
    required this.evaluations,
  });
}

class StudentTranscript {
  final String studentCode;
  final String studentName;
  final List<TranscriptCourseRow> courses;
  final int rankingPosition;
  final int rankingTotal;
  final double rankingPercentile;

  const StudentTranscript({
    required this.studentCode,
    required this.studentName,
    required this.courses,
    this.rankingPosition = 0,
    this.rankingTotal = 0,
    this.rankingPercentile = 0,
  });

  int get approvedCourses =>
      courses.where((item) => item.hasGrades && item.approved).length;

  int get failedCourses =>
      courses.where((item) => item.hasGrades && !item.approved).length;

  int get pendingCourses => courses.where((item) => !item.hasGrades).length;

  double get generalAverage {
    final evaluated = courses.where((item) => item.hasGrades).toList();

    if (evaluated.isEmpty) return 0;

    return evaluated.map((item) => item.average).reduce((a, b) => a + b) /
        evaluated.length;
  }

  double get gpa4 {
    final avg = generalAverage;

    if (avg >= 90) return 4.0;
    if (avg >= 85) return 3.7;
    if (avg >= 80) return 3.3;
    if (avg >= 75) return 3.0;
    if (avg >= 70) return 2.7;
    if (avg >= 65) return 2.0;
    if (avg >= 60) return 1.0;

    return 0.0;
  }

  String get academicStanding {
    final avg = generalAverage;

    if (approvedCourses == 0 && failedCourses == 0) return 'Pendiente';
    if (avg >= 90) return 'Excelencia académica';
    if (avg >= 85) return 'Honor académico';
    if (avg >= 80) return 'Mérito académico';
    if (avg >= 70) return 'Satisfactorio';

    return 'Riesgo académico';
  }

  List<String> get distinctions {
    final items = <String>[];

    if (generalAverage >= 90) {
      items.add('Excelencia académica');
    } else if (generalAverage >= 85) {
      items.add('Honor académico');
    } else if (generalAverage >= 80) {
      items.add('Mérito académico');
    }

    if (attendanceAverage >= 95) {
      items.add('Asistencia destacada');
    }

    if (approvedCourses > 0 && failedCourses == 0) {
      items.add('Trayectoria sin reprobación');
    }

    return items;
  }

  double get attendanceAverage {
    final withAttendance = courses.where((item) => item.hasAttendance).toList();

    if (withAttendance.isEmpty) return 0;

    return withAttendance
            .map((item) => item.attendanceRate)
            .reduce((a, b) => a + b) /
        withAttendance.length;
  }
}

class StudentTranscriptService {
  static Future<StudentTranscript?> buildTranscript({
    required String studentCode,
    required String studentName,
  }) async {
    final courses = await CourseService.getCourses();
    final students = await StudentRosterService.getStudents();

    final transcriptRows = <TranscriptCourseRow>[];
    StudentRanking? bestRanking;

    for (final course in courses) {
      final report = await AcademicAnalyticsService.buildFinalReport(
        courseId: course.id,
        courseName: course.name,
      );

      final match = report.where((summary) {
        final sameCode = summary.studentCode.trim().toLowerCase() ==
            studentCode.trim().toLowerCase();

        final sameName = summary.studentName.trim().toLowerCase() ==
            studentName.trim().toLowerCase();

        return sameCode || sameName;
      }).toList();

      if (match.isEmpty) continue;

      final item = match.first;

      final courseRanking = AcademicAnalyticsService.rankSummaries(report);
      for (final ranking in courseRanking) {
        final sameCode = ranking.studentCode.trim().toLowerCase() ==
            studentCode.trim().toLowerCase();
        final sameName = ranking.studentName.trim().toLowerCase() ==
            studentName.trim().toLowerCase();

        if (sameCode || sameName) {
          if (bestRanking == null ||
              ranking.percentile > bestRanking.percentile) {
            bestRanking = ranking;
          }
          break;
        }
      }

      transcriptRows.add(
        TranscriptCourseRow(
          courseId: course.id,
          courseName: course.displayName,
          average: item.average,
          attendanceRate: item.attendanceRate,
          hasGrades: item.hasGrades,
          hasAttendance: item.hasAttendance,
          approved: item.approved,
          evaluations: item.evaluations,
        ),
      );
    }

    if (transcriptRows.isEmpty && students.isEmpty) return null;

    return StudentTranscript(
      studentCode: studentCode,
      studentName: studentName,
      courses: transcriptRows,
      rankingPosition: bestRanking?.rank ?? 0,
      rankingTotal: bestRanking?.totalStudents ?? 0,
      rankingPercentile: bestRanking?.percentile ?? 0,
    );
  }
}
