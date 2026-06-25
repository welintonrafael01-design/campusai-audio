import 'dart:convert';
import 'dart:html' as html;

import 'package:shared_preferences/shared_preferences.dart';

import 'assessment_weight_service.dart';
import 'educator_sync_service.dart';
import 'student_roster_service.dart';

class GradebookEntry {
  final String id;
  final String studentId;
  final String studentName;
  final String studentCode;
  final String course;
  final String courseId;
  final String rubricTitle;
  final double score;
  final double maxScore;
  final String createdAt;
  final String notes;

  const GradebookEntry({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentCode = '',
    required this.course,
    this.courseId = '',
    required this.rubricTitle,
    required this.score,
    required this.maxScore,
    required this.createdAt,
    this.notes = '',
  });

  bool get isValid => studentName.trim().isNotEmpty && maxScore > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'studentCode': studentCode,
        'course': course,
        'courseId': courseId,
        'rubricTitle': rubricTitle,
        'score': score,
        'maxScore': maxScore,
        'createdAt': createdAt,
        'notes': notes,
      };

  factory GradebookEntry.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return GradebookEntry(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      studentCode: json['studentCode']?.toString() ??
          json['student_code']?.toString() ??
          '',
      course: json['course']?.toString() ?? '',
      courseId:
          json['courseId']?.toString() ?? json['course_id']?.toString() ?? '',
      rubricTitle: json['rubricTitle']?.toString() ?? '',
      score: asDouble(json['score']),
      maxScore: asDouble(json['maxScore']),
      createdAt: json['createdAt']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class GradebookActivity {
  final String id;
  final String title;
  final String type;
  final String unitId;
  final String unitTopic;
  final String courseId;
  final String courseName;
  final String sourceDocumentId;
  final String sourceResultId;
  final double totalPoints;
  final double weight;
  final String rubricId;
  final String examId;
  final String assessmentReportId;
  final String createdAt;

  const GradebookActivity({
    required this.id,
    required this.title,
    required this.type,
    this.unitId = '',
    this.unitTopic = '',
    this.courseId = '',
    this.courseName = '',
    this.sourceDocumentId = '',
    this.sourceResultId = '',
    this.totalPoints = 100,
    this.weight = 0,
    this.rubricId = '',
    this.examId = '',
    this.assessmentReportId = '',
    required this.createdAt,
  });

  bool get isValid =>
      title.trim().isNotEmpty && sourceResultId.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'unit_id': unitId,
        'unit_topic': unitTopic,
        'course_id': courseId,
        'course_name': courseName,
        'source_document_id': sourceDocumentId,
        'source_result_id': sourceResultId,
        'total_points': totalPoints,
        'weight': weight,
        'rubric_id': rubricId,
        'exam_id': examId,
        'assessment_report_id': assessmentReportId,
        'createdAt': createdAt,
      };

  factory GradebookActivity.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic value, [double fallback = 0]) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return GradebookActivity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      unitId: json['unit_id']?.toString() ?? json['unitId']?.toString() ?? '',
      unitTopic:
          json['unit_topic']?.toString() ?? json['unitTopic']?.toString() ?? '',
      courseId:
          json['course_id']?.toString() ?? json['courseId']?.toString() ?? '',
      courseName: json['course_name']?.toString() ??
          json['courseName']?.toString() ??
          '',
      sourceDocumentId: json['source_document_id']?.toString() ??
          json['sourceDocumentId']?.toString() ??
          '',
      sourceResultId: json['source_result_id']?.toString() ??
          json['sourceResultId']?.toString() ??
          '',
      totalPoints: asDouble(json['total_points'] ?? json['totalPoints'], 100),
      weight: asDouble(json['weight']),
      rubricId:
          json['rubric_id']?.toString() ?? json['rubricId']?.toString() ?? '',
      examId: json['exam_id']?.toString() ?? json['examId']?.toString() ?? '',
      assessmentReportId: json['assessment_report_id']?.toString() ??
          json['assessmentReportId']?.toString() ??
          '',
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }
}

class GradebookService {
  static const String _key = 'studybook_gradebook_entries';
  static const String _activitiesKey = 'studybook_gradebook_activities';

  static Future<List<GradebookEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return GradebookEntry.fromJson(decoded);
            }
            if (decoded is Map) {
              return GradebookEntry.fromJson(
                  Map<String, dynamic>.from(decoded));
            }
          } catch (_) {}
          return null;
        })
        .whereType<GradebookEntry>()
        .where((item) => item.isValid)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveEntry(GradebookEntry entry) async {
    final entries = await getEntries();

    entries.removeWhere((item) => item.id == entry.id);
    entries.insert(0, entry);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      entries.map((item) => jsonEncode(item.toJson())).toList(),
    );

    await EducatorSyncService.syncAfterLocalWrite();
  }

  static Future<List<GradebookActivity>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_activitiesKey) ?? [];

    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return GradebookActivity.fromJson(decoded);
            }
            if (decoded is Map) {
              return GradebookActivity.fromJson(
                Map<String, dynamic>.from(decoded),
              );
            }
          } catch (_) {}
          return null;
        })
        .whereType<GradebookActivity>()
        .where((item) => item.isValid)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<bool> addActivityFromAcademicResource({
    required String title,
    required String type,
    required String unitId,
    required String unitTopic,
    required String courseId,
    required String courseName,
    required String sourceDocumentId,
    required String sourceResultId,
    required double totalPoints,
    double weight = 0,
    String rubricId = '',
    String examId = '',
    String assessmentReportId = '',
  }) async {
    final activities = await getActivities();

    if (activities.any((item) => item.sourceResultId == sourceResultId)) {
      return false;
    }

    final now = DateTime.now().toIso8601String();

    activities.insert(
      0,
      GradebookActivity(
        id: 'academic_engine_${sourceResultId}_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        type: type,
        unitId: unitId,
        unitTopic: unitTopic,
        courseId: courseId,
        courseName: courseName,
        sourceDocumentId: sourceDocumentId,
        sourceResultId: sourceResultId,
        totalPoints: totalPoints,
        weight: weight,
        rubricId: rubricId,
        examId: examId,
        assessmentReportId: assessmentReportId,
        createdAt: now,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _activitiesKey,
      activities.map((item) => jsonEncode(item.toJson())).toList(),
    );

    await EducatorSyncService.syncAfterLocalWrite();
    return true;
  }

  static Future<Map<String, dynamic>> buildFinalReportFromGradebook({
    required String courseId,
    required String courseName,
    String courseCode = '',
    String courseSection = '',
    String coursePeriod = '',
  }) async {
    final allEntries = await getEntries();
    final allActivities = await getActivities();
    final allStudents = await StudentRosterService.getStudents();
    final weights = await AssessmentWeightService.getWeights(courseId);

    bool matchesCourse({
      String itemCourseId = '',
      String itemCourseName = '',
    }) {
      final cleanCourseId = itemCourseId.trim();
      final cleanCourseName = itemCourseName.toLowerCase().trim();

      if (cleanCourseId.isNotEmpty && cleanCourseId == courseId) return true;
      if (cleanCourseName.isNotEmpty &&
          cleanCourseName == courseName.toLowerCase().trim()) {
        return true;
      }

      return cleanCourseId.isEmpty && cleanCourseName.isEmpty;
    }

    final entries = allEntries
        .where(
          (entry) => matchesCourse(
            itemCourseId: entry.courseId,
            itemCourseName: entry.course,
          ),
        )
        .toList();
    final activities = allActivities
        .where(
          (activity) => matchesCourse(
            itemCourseId: activity.courseId,
            itemCourseName: activity.courseName,
          ),
        )
        .toList();
    final roster = allStudents
        .where(
          (student) => matchesCourse(
            itemCourseId: student.courseId,
            itemCourseName: student.course,
          ),
        )
        .toList();

    final expectedActivities = activities.isNotEmpty
        ? activities
            .map((item) => item.title.trim())
            .where((item) {
              return item.isNotEmpty;
            })
            .toSet()
            .toList()
        : entries
            .map((item) => item.rubricTitle.trim())
            .where((item) {
              return item.isNotEmpty;
            })
            .toSet()
            .toList();

    expectedActivities.sort();

    final students = <String, Map<String, String>>{};

    String studentKey({
      required String id,
      required String code,
      required String name,
    }) {
      if (code.trim().isNotEmpty) return 'code:${code.trim()}';
      if (id.trim().isNotEmpty) return 'id:${id.trim()}';
      return 'name:${name.toLowerCase().trim()}';
    }

    for (final student in roster) {
      final key = studentKey(
        id: student.id,
        code: student.studentCode,
        name: student.name,
      );

      students[key] = {
        'id': student.id,
        'code': student.studentCode,
        'name': student.name,
      };
    }

    for (final entry in entries) {
      final key = studentKey(
        id: entry.studentId,
        code: entry.studentCode,
        name: entry.studentName,
      );

      students.putIfAbsent(
        key,
        () => {
          'id': entry.studentId,
          'code': entry.studentCode,
          'name': entry.studentName,
        },
      );
    }

    final reportStudents = <Map<String, dynamic>>[];

    for (final student in students.values) {
      final studentEntries = entries.where((entry) {
        final entryCode = entry.studentCode.trim();
        final entryId = entry.studentId.trim();
        final entryName = entry.studentName.toLowerCase().trim();
        final studentCode = student['code']?.trim() ?? '';
        final studentId = student['id']?.trim() ?? '';
        final studentName = student['name']?.toLowerCase().trim() ?? '';

        if (studentCode.isNotEmpty && entryCode == studentCode) return true;
        if (studentId.isNotEmpty && entryId == studentId) return true;
        return studentName.isNotEmpty && entryName == studentName;
      }).toList();

      final completedActivities = studentEntries
          .map((entry) => entry.rubricTitle.trim())
          .where((item) => item.isNotEmpty)
          .toSet();
      final missingActivities = expectedActivities
          .where((activity) => !completedActivities.contains(activity))
          .toList();
      final hasExpectedActivities = expectedActivities.isNotEmpty;
      final hasGrades = studentEntries.isNotEmpty;
      final hasSufficientGrades = hasExpectedActivities
          ? missingActivities.isEmpty && hasGrades
          : hasGrades;
      final finalScore = hasGrades
          ? AssessmentWeightService.weightedAverage(
              grades: studentEntries,
              weights: weights,
              percentageBuilder: (entry) {
                final grade = entry as GradebookEntry;
                if (grade.maxScore <= 0) return 0;
                return (grade.score / grade.maxScore) * 100;
              },
              assessmentNameBuilder: (entry) {
                return (entry as GradebookEntry).rubricTitle;
              },
            )
          : 0.0;
      final status = !hasSufficientGrades
          ? 'Incompleto'
          : finalScore >= 70
              ? 'Aprobado'
              : 'Reprobado';
      final observations = <String>[];

      if (status == 'Aprobado') {
        observations.add('Cumple los criterios de aprobación.');
      }
      if (status == 'Reprobado') {
        observations.add('Debe reforzar competencias evaluadas.');
      }
      if (missingActivities.isNotEmpty) {
        observations.add('Tiene actividades pendientes por completar.');
      }
      if (!hasSufficientGrades) {
        observations.add('No tiene calificaciones suficientes para cierre.');
      }

      reportStudents.add({
        'student_id': student['id'] ?? '',
        'student_code': student['code'] ?? '',
        'student_name': student['name'] ?? '',
        'final_score': finalScore.round(),
        'status': status,
        'missing_activities': missingActivities,
        'observations': observations,
      });
    }

    reportStudents.sort(
      (a, b) => (a['student_name'] ?? '')
          .toString()
          .compareTo((b['student_name'] ?? '').toString()),
    );

    final approved =
        reportStudents.where((item) => item['status'] == 'Aprobado').length;
    final failed =
        reportStudents.where((item) => item['status'] == 'Reprobado').length;
    final incomplete =
        reportStudents.where((item) => item['status'] == 'Incompleto').length;
    final numericScores = reportStudents
        .where((item) => item['status'] != 'Incompleto')
        .map((item) {
      final value = item['final_score'];
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }).toList();
    final averageScore = numericScores.isEmpty
        ? 0
        : (numericScores.reduce((a, b) => a + b) / numericScores.length)
            .round();

    return {
      'course_id': courseId,
      'course_name': courseName,
      'course_code': courseCode,
      'course_section': courseSection,
      'course_period': coursePeriod,
      'generated_at': DateTime.now().toIso8601String(),
      'activities': activities.map((item) => item.toJson()).toList(),
      'expected_activities': expectedActivities,
      'students': reportStudents,
      'summary': {
        'total_students': reportStudents.length,
        'approved': approved,
        'failed': failed,
        'incomplete': incomplete,
        'average_score': averageScore,
      },
    };
  }

  static Future<void> deleteEntry(String id) async {
    final entries = await getEntries();
    entries.removeWhere((item) => item.id == id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      entries.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  static Future<void> exportCsv() async {
    final entries = await getEntries();

    final buffer = StringBuffer();
    buffer.writeln(
        'student_code,student_name,course,rubric_title,score,max_score,percentage,date,notes');

    for (final entry in entries) {
      final percentage =
          entry.maxScore <= 0 ? 0 : (entry.score / entry.maxScore) * 100;

      buffer.writeln(
        [
          _csv(entry.studentCode),
          _csv(entry.studentName),
          _csv(entry.course),
          _csv(entry.rubricTitle),
          entry.score.toStringAsFixed(1),
          entry.maxScore.toStringAsFixed(1),
          percentage.toStringAsFixed(1),
          _csv(entry.createdAt),
          _csv(entry.notes),
        ].join(','),
      );
    }

    final blob = html.Blob(
      [utf8.encode(buffer.toString())],
      'text/csv;charset=utf-8',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', 'studybook_libro_calificaciones.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  static Future<int> importGradesCsvFromUser({
    required String courseId,
    required String courseName,
  }) async {
    final upload = html.FileUploadInputElement()
      ..accept = '.csv,text/csv'
      ..click();

    await upload.onChange.first;

    final file = upload.files?.first;
    if (file == null) return 0;

    final reader = html.FileReader();
    reader.readAsText(file);

    await reader.onLoad.first;

    final content = reader.result?.toString() ?? '';
    final rows = content
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (rows.isEmpty) return 0;

    final entries = await getEntries();
    var imported = 0;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final lower = row.toLowerCase();

      if (i == 0 &&
          (lower.contains('student_code') ||
              lower.contains('codigo') ||
              lower.contains('score'))) {
        continue;
      }

      final cols = _parseCsvLine(row);

      final studentCode = cols.isNotEmpty ? cols[0].trim() : '';
      final studentName = cols.length > 1 ? cols[1].trim() : '';
      final score = cols.length > 2 ? double.tryParse(cols[2].trim()) ?? 0 : 0;
      final maxScore =
          cols.length > 3 ? double.tryParse(cols[3].trim()) ?? 100 : 100;
      final assessment = cols.length > 4 && cols[4].trim().isNotEmpty
          ? cols[4].trim()
          : 'Evaluación masiva';

      if (studentName.isEmpty && studentCode.isEmpty) continue;

      final id =
          '${courseId}_${studentCode}_${assessment}_${DateTime.now().millisecondsSinceEpoch}_$i';

      entries.insert(
        0,
        GradebookEntry(
          id: id,
          studentId: studentCode,
          studentCode: studentCode,
          studentName: studentName.isEmpty ? studentCode : studentName,
          course: courseName,
          courseId: courseId,
          rubricTitle: assessment,
          score: score.toDouble(),
          maxScore: maxScore.toDouble(),
          createdAt: DateTime.now().toIso8601String(),
          notes: 'Importado desde CSV',
        ),
      );

      imported++;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _key,
      entries.map((item) => jsonEncode(item.toJson())).toList(),
    );

    return imported;
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var insideQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (char == ',' && !insideQuotes) {
        result.add(buffer.toString().replaceAll('""', '"'));
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    result.add(buffer.toString().replaceAll('""', '"'));
    return result;
  }

  static String _csv(String value) {
    final clean = value.replaceAll('"', '""');
    return '"$clean"';
  }
}
