import 'dart:convert';
import 'dart:html' as html;

import 'package:shared_preferences/shared_preferences.dart';

class StudentRecord {
  final String id;
  final String name;
  final String course;
  final String email;

  const StudentRecord({
    required this.id,
    required this.name,
    this.course = '',
    this.email = '',
  });

  bool get isValid => name.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'course': course,
        'email': email,
      };

  factory StudentRecord.fromJson(Map<String, dynamic> json) {
    return StudentRecord(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      course: json['course']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class StudentRosterService {
  static const String _key = 'studybook_students_roster';

  static Future<List<StudentRecord>> getStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return StudentRecord.fromJson(decoded);
            }
            if (decoded is Map) {
              return StudentRecord.fromJson(Map<String, dynamic>.from(decoded));
            }
          } catch (_) {}
          return null;
        })
        .whereType<StudentRecord>()
        .where((item) => item.isValid)
        .toList();
  }

  static Future<void> saveStudents(List<StudentRecord> students) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = students
        .where((item) => item.isValid)
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await prefs.setStringList(_key, encoded);
  }

  static Future<void> addStudent(StudentRecord student) async {
    final students = await getStudents();

    students.removeWhere(
      (item) =>
          item.id == student.id ||
          item.name.toLowerCase().trim() == student.name.toLowerCase().trim(),
    );

    students.add(student);
    students.sort((a, b) => a.name.compareTo(b.name));

    await saveStudents(students);
  }

  static Future<void> deleteStudent(String id) async {
    final students = await getStudents();
    students.removeWhere((item) => item.id == id);
    await saveStudents(students);
  }

  static Future<void> exportCsv() async {
    final students = await getStudents();

    final buffer = StringBuffer();
    buffer.writeln('name,course,email');

    for (final student in students) {
      buffer.writeln(
        '${_csv(student.name)},${_csv(student.course)},${_csv(student.email)}',
      );
    }

    final blob = html.Blob(
      [utf8.encode(buffer.toString())],
      'text/csv;charset=utf-8',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', 'studybook_estudiantes.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  static Future<List<StudentRecord>> importCsvFromUser() async {
    final upload = html.FileUploadInputElement()
      ..accept = '.csv,text/csv'
      ..click();

    await upload.onChange.first;

    final file = upload.files?.first;
    if (file == null) return [];

    final reader = html.FileReader();
    reader.readAsText(file);

    await reader.onLoad.first;

    final content = reader.result?.toString() ?? '';
    final rows = content
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (rows.isEmpty) return [];

    final imported = <StudentRecord>[];

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];

      if (i == 0 && row.toLowerCase().contains('name')) continue;
      if (i == 0 && row.toLowerCase().contains('nombre')) continue;

      final cols = _parseCsvLine(row);

      final name = cols.isNotEmpty ? cols[0].trim() : '';
      final course = cols.length > 1 ? cols[1].trim() : '';
      final email = cols.length > 2 ? cols[2].trim() : '';

      if (name.isEmpty) continue;

      imported.add(
        StudentRecord(
          id: '${DateTime.now().microsecondsSinceEpoch}_$i',
          name: name,
          course: course,
          email: email,
        ),
      );
    }

    final current = await getStudents();
    final merged = [...current];

    for (final student in imported) {
      merged.removeWhere(
        (item) =>
            item.name.toLowerCase().trim() == student.name.toLowerCase().trim(),
      );
      merged.add(student);
    }

    merged.sort((a, b) => a.name.compareTo(b.name));

    await saveStudents(merged);

    return imported;
  }

  static String _csv(String value) {
    final clean = value.replaceAll('"', '""');
    return '"$clean"';
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
}
