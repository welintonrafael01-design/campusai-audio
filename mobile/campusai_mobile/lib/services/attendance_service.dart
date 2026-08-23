import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'educator_sync_service.dart';

import 'student_roster_service.dart';
import 'platform_file_service.dart';

class AttendanceEntry {
  final String id;
  final String studentId;
  final String studentName;
  final String course;
  final String courseId;
  final String date;
  final String status;
  final String note;

  const AttendanceEntry({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.course,
    this.courseId = '',
    required this.date,
    required this.status,
    this.note = '',
  });

  bool get isValid =>
      studentName.trim().isNotEmpty &&
      date.trim().isNotEmpty &&
      status.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'course': course,
        'courseId': courseId,
        'date': date,
        'status': status,
        'note': note,
      };

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceEntry(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      course: json['course']?.toString() ?? '',
      courseId:
          json['courseId']?.toString() ?? json['course_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }
}

class AttendanceService {
  static const String _key = 'studybook_attendance_entries';
  static String get _scopedKey => EducatorSyncService.scopedKey(_key);

  static Future<List<AttendanceEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_scopedKey) ?? [];

    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return AttendanceEntry.fromJson(decoded);
            }
            if (decoded is Map) {
              return AttendanceEntry.fromJson(
                Map<String, dynamic>.from(decoded),
              );
            }
          } catch (_) {}
          return null;
        })
        .whereType<AttendanceEntry>()
        .where((item) => item.isValid)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveEntriesForDate({
    required String date,
    required List<AttendanceEntry> entries,
  }) async {
    final current = await getEntries();

    final entryKeys =
        entries.map((item) => '${item.courseId}::${item.studentId}').toSet();

    current.removeWhere(
      (item) =>
          item.date == date &&
          entryKeys.contains('${item.courseId}::${item.studentId}'),
    );

    current.addAll(entries.where((item) => item.isValid));

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _scopedKey,
      current.map((item) => jsonEncode(item.toJson())).toList(),
    );

    await EducatorSyncService.syncAfterLocalWrite();
  }

  static Future<void> deleteEntry(String id) async {
    final entries = await getEntries();
    entries.removeWhere((item) => item.id == id);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _scopedKey,
      entries.map((item) => jsonEncode(item.toJson())).toList(),
    );

    await EducatorSyncService.syncAfterLocalWrite();
  }

  static Future<void> exportCsv() async {
    final entries = await getEntries();

    final buffer = StringBuffer();
    buffer.writeln('student_name,course,date,status,note');

    for (final entry in entries) {
      buffer.writeln(
        [
          _csv(entry.studentName),
          _csv(entry.course),
          _csv(entry.date),
          _csv(entry.status),
          _csv(entry.note),
        ].join(','),
      );
    }

    await PlatformFileService.saveTextFile(
      filename: 'studybook_asistencia.csv',
      content: buffer.toString(),
      dialogTitle: 'Exportar asistencia',
    );
  }

  static Future<int> importAttendanceCsvFromUser() async {
    final content = await PlatformFileService.pickTextFile();

    if (content == null) return 0;
    final rows = content
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (rows.isEmpty) return 0;

    final importedEntries = <AttendanceEntry>[];
    final importedStudents = <StudentRecord>[];

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i].trim();
      final lower = row.toLowerCase();

      if (i == 0 &&
          (lower.contains('name') ||
              lower.contains('nombre') ||
              lower.contains('student'))) {
        continue;
      }

      final cols = _parseCsvLine(row);

      final name = cols.isNotEmpty ? cols[0].trim() : '';
      final course = cols.length > 1 ? cols[1].trim() : '';
      final email = cols.length > 2 ? cols[2].trim() : '';
      final status = cols.length > 3 && cols[3].trim().isNotEmpty
          ? cols[3].trim()
          : 'Presente';
      final date = cols.length > 4 && cols[4].trim().isNotEmpty
          ? cols[4].trim()
          : DateTime.now().toIso8601String().substring(0, 10);
      final note = cols.length > 5 ? cols[5].trim() : '';

      if (name.isEmpty) continue;

      final studentId =
          '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${course.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

      importedStudents.add(
        StudentRecord(
          id: studentId,
          name: name,
          course: course,
          email: email,
          studentCode: studentId,
        ),
      );

      importedEntries.add(
        AttendanceEntry(
          id: '${studentId}_$date',
          studentId: studentId,
          studentName: name,
          course: course,
          date: date,
          status: status,
          note: note,
        ),
      );
    }

    final currentStudents = await StudentRosterService.getStudents();
    final mergedStudents = [...currentStudents];

    for (final student in importedStudents) {
      mergedStudents.removeWhere(
        (item) =>
            item.name.toLowerCase().trim() ==
                student.name.toLowerCase().trim() &&
            item.course.toLowerCase().trim() ==
                student.course.toLowerCase().trim(),
      );
      mergedStudents.add(student);
    }

    mergedStudents.sort((a, b) => a.name.compareTo(b.name));
    await StudentRosterService.saveStudents(mergedStudents);

    final currentEntries = await getEntries();
    final mergedEntries = [...currentEntries];

    for (final entry in importedEntries) {
      mergedEntries.removeWhere(
        (item) => item.studentId == entry.studentId && item.date == entry.date,
      );
      mergedEntries.add(entry);
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _scopedKey,
      mergedEntries.map((item) => jsonEncode(item.toJson())).toList(),
    );

    await EducatorSyncService.syncAfterLocalWrite();

    return importedEntries.length;
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
