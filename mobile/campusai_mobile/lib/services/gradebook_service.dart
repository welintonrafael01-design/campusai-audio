import 'dart:convert';
import 'dart:html' as html;

import 'package:shared_preferences/shared_preferences.dart';

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
      courseId: json['courseId']?.toString() ??
          json['course_id']?.toString() ??
          '',
      rubricTitle: json['rubricTitle']?.toString() ?? '',
      score: asDouble(json['score']),
      maxScore: asDouble(json['maxScore']),
      createdAt: json['createdAt']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class GradebookService {
  static const String _key = 'studybook_gradebook_entries';

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
              return GradebookEntry.fromJson(Map<String, dynamic>.from(decoded));
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
    buffer.writeln('student_code,student_name,course,rubric_title,score,max_score,percentage,date,notes');

    for (final entry in entries) {
      final percentage = entry.maxScore <= 0
          ? 0
          : (entry.score / entry.maxScore) * 100;

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
      final maxScore = cols.length > 3 ? double.tryParse(cols[3].trim()) ?? 100 : 100;
      final assessment = cols.length > 4 && cols[4].trim().isNotEmpty
          ? cols[4].trim()
          : 'Evaluación masiva';

      if (studentName.isEmpty && studentCode.isEmpty) continue;

      final id = '${courseId}_${studentCode}_${assessment}_${DateTime.now().millisecondsSinceEpoch}_$i';

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
