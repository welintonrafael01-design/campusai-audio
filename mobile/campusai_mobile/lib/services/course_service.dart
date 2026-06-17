import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CourseRecord {
  final String id;
  final String name;
  final String code;
  final String section;
  final String period;

  const CourseRecord({
    required this.id,
    required this.name,
    this.code = '',
    this.section = '',
    this.period = '',
  });

  String get displayName {
    final cleanCode = code.trim();
    final cleanName = name.trim();

    final parts = [
      if (cleanCode.isNotEmpty) cleanCode,
      cleanName,
      if (section.trim().isNotEmpty) section,
      if (period.trim().isNotEmpty) period,
    ];

    return parts.where((item) => item.trim().isNotEmpty).join(' - ');
  }

  bool get isValid => name.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'section': section,
        'period': period,
      };

  factory CourseRecord.fromJson(Map<String, dynamic> json) {
    return CourseRecord(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ??
          json['courseCode']?.toString() ??
          json['course_code']?.toString() ??
          '',
      section: json['section']?.toString() ?? '',
      period: json['period']?.toString() ?? '',
    );
  }
}

class CourseService {
  static const String _key = 'studybook_courses';
  static const String _activeKey = 'studybook_active_course';

  static Future<List<CourseRecord>> getCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return CourseRecord.fromJson(decoded);
            }
            if (decoded is Map) {
              return CourseRecord.fromJson(Map<String, dynamic>.from(decoded));
            }
          } catch (_) {}
          return null;
        })
        .whereType<CourseRecord>()
        .where((item) => item.isValid)
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  static Future<void> saveCourses(List<CourseRecord> courses) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _key,
      courses
          .where((item) => item.isValid)
          .map((item) => jsonEncode(item.toJson()))
          .toList(),
    );
  }

  static Future<void> addCourse(CourseRecord course) async {
    final courses = await getCourses();

    courses.removeWhere(
      (item) =>
          item.id == course.id ||
          item.displayName.toLowerCase().trim() ==
              course.displayName.toLowerCase().trim(),
    );

    courses.add(course);
    await saveCourses(courses);
    await setActiveCourse(course.id);
  }

  static Future<String> getActiveCourseId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeKey) ?? '';
  }

  static Future<void> setActiveCourse(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, courseId);
  }


  static String inferCourseCode(String courseName) {
    final text = courseName.trim();

    final codeMatch = RegExp(r'\b[A-Z]{2,5}\s*-?\s*\d{2,6}\b')
        .firstMatch(text.toUpperCase());

    if (codeMatch != null) {
      return codeMatch.group(0)!.replaceAll(RegExp(r'\s+|-'), '');
    }

    final compactMatch = RegExp(r'\b[A-Z]{2,5}\d{2,6}\b')
        .firstMatch(text.toUpperCase());

    if (compactMatch != null) {
      return compactMatch.group(0)!;
    }

    return '';
  }

  static String buildAutoCourseCode(String courseName) {
    final words = courseName
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList();

    final letters = words
        .where((word) => RegExp(r'^[A-Z]+$').hasMatch(word))
        .take(3)
        .map((word) => word.substring(0, 1))
        .join();

    final base = letters.isEmpty ? 'CUR' : letters.padRight(3, 'X');
    final number = courseName.hashCode.abs().toString().padLeft(6, '0');

    return '$base${number.substring(0, 3)}';
  }

  static CourseRecord buildCourseFromName(String courseName) {
    final clean = courseName.trim();
    final detectedCode = inferCourseCode(clean);
    final code = detectedCode.isNotEmpty
        ? detectedCode
        : buildAutoCourseCode(clean);

    return CourseRecord(
      id: buildId(clean, section: code),
      name: clean,
      code: code,
    );
  }

  static String buildId(String name, {String section = '', String period = ''}) {
    final raw = '$name $section $period'.toLowerCase().trim();

    final clean = raw.replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    return clean.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }


  static Future<void> ensureCoursesFromNames(List<String> courseNames) async {
    final courses = await getCourses();
    final existingIds = courses.map((item) => item.id).toSet();

    for (final courseName in courseNames) {
      final clean = courseName.trim();
      if (clean.isEmpty) continue;

      final course = buildCourseFromName(clean);
      final id = course.id;
      if (existingIds.contains(id)) continue;

      courses.add(course);
      existingIds.add(id);
    }

    await saveCourses(courses);

    final active = await getActiveCourseId();
    if (active.isEmpty && courses.isNotEmpty) {
      await setActiveCourse(courses.first.id);
    }
  }

  static Future<void> ensureCourseFromName(String courseName) async {
    final clean = courseName.trim();
    if (clean.isEmpty) return;

    final course = buildCourseFromName(clean);
    final id = course.id;

    final courses = await getCourses();
    if (courses.any((item) => item.id == id)) return;

    courses.add(course);
    await saveCourses(courses);
  }
}
