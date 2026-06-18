import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AssessmentWeight {
  final String name;
  final double weight;

  const AssessmentWeight({
    required this.name,
    required this.weight,
  });

  bool get isValid => name.trim().isNotEmpty && weight > 0;

  Map<String, dynamic> toJson() => {
        'name': name,
        'weight': weight,
      };

  factory AssessmentWeight.fromJson(Map<String, dynamic> json) {
    final value = json['weight'];
    return AssessmentWeight(
      name: json['name']?.toString() ?? '',
      weight: value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '') ?? 0,
    );
  }
}

class AssessmentWeightService {
  static const String _prefix = 'studybook_assessment_weights_';

  static String _key(String courseId) => '$_prefix$courseId';

  static Future<List<AssessmentWeight>> getWeights(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(courseId)) ?? [];

    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return AssessmentWeight.fromJson(decoded);
            }
            if (decoded is Map) {
              return AssessmentWeight.fromJson(Map<String, dynamic>.from(decoded));
            }
          } catch (_) {}
          return null;
        })
        .whereType<AssessmentWeight>()
        .where((item) => item.isValid)
        .toList();
  }

  static Future<void> saveWeights({
    required String courseId,
    required List<AssessmentWeight> weights,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _key(courseId),
      weights
          .where((item) => item.isValid)
          .map((item) => jsonEncode(item.toJson()))
          .toList(),
    );
  }

  static double weightedAverage({
    required List<dynamic> grades,
    required List<AssessmentWeight> weights,
    required double Function(dynamic entry) percentageBuilder,
    required String Function(dynamic entry) assessmentNameBuilder,
  }) {
    if (grades.isEmpty) return 0;

    if (weights.isEmpty) {
      final values = grades.map(percentageBuilder).toList();
      if (values.isEmpty) return 0;
      return values.reduce((a, b) => a + b) / values.length;
    }

    var weightedTotal = 0.0;
    var usedWeight = 0.0;

    for (final entry in grades) {
      final assessmentName = assessmentNameBuilder(entry).toLowerCase().trim();

      final matches = weights.where(
        (item) =>
            assessmentName.contains(item.name.toLowerCase().trim()) ||
            item.name.toLowerCase().trim().contains(assessmentName),
      );

      if (matches.isEmpty) continue;

      final weight = matches.first.weight;
      weightedTotal += percentageBuilder(entry) * weight;
      usedWeight += weight;
    }

    if (usedWeight <= 0) {
      final values = grades.map(percentageBuilder).toList();
      if (values.isEmpty) return 0;
      return values.reduce((a, b) => a + b) / values.length;
    }

    return weightedTotal / usedWeight;
  }
}
