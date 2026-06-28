import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/study_result.dart';
import '../services/academic_analytics_service.dart';
import '../services/academic_engine/academic_resource_repository.dart';
import '../services/academic_engine/curriculum_intelligence_engine.dart';
import '../services/course_service.dart';
import '../services/study_result_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class AcademicDashboardScreen extends StatefulWidget {
  const AcademicDashboardScreen({super.key});

  @override
  State<AcademicDashboardScreen> createState() =>
      _AcademicDashboardScreenState();
}

class _AcademicDashboardScreenState extends State<AcademicDashboardScreen> {
  List<CourseRecord> courses = [];
  String activeCourseId = '';
  List<StudentAcademicSummary> summaries = [];
  List<StudentRanking> globalRanking = [];
  Map<String, dynamic> curriculumIntelligence = {};
  bool curriculumIntelligenceUnavailable = false;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final loadedCourses = await CourseService.getCourses();
    final storedActiveCourseId = await CourseService.getActiveCourseId();

    final resolvedActiveCourseId = storedActiveCourseId.isNotEmpty
        ? storedActiveCourseId
        : (loadedCourses.isNotEmpty ? loadedCourses.first.id : '');

    final activeCourse = loadedCourses
        .where((item) => item.id == resolvedActiveCourseId)
        .cast<CourseRecord?>()
        .firstOrNull;

    final data = activeCourse == null
        ? <StudentAcademicSummary>[]
        : await AcademicAnalyticsService.buildFinalReport(
            courseId: activeCourse.id,
            courseName: activeCourse.name,
          );

    final globalData = await AcademicAnalyticsService.buildGlobalRanking();
    final intelligence = await loadCurriculumIntelligence(
      activeCourse: activeCourse,
    );

    if (!mounted) return;

    setState(() {
      courses = loadedCourses;
      activeCourseId = resolvedActiveCourseId;
      summaries = data;
      globalRanking = globalData;
      curriculumIntelligence = intelligence;
      curriculumIntelligenceUnavailable = intelligence.isEmpty;
    });
  }

  Future<Map<String, dynamic>> loadCurriculumIntelligence({
    required CourseRecord? activeCourse,
  }) async {
    try {
      final plans = await StudyResultService.getResultsByType('teaching_plan');
      final selectedPlan = selectTeachingPlanForCourse(plans, activeCourse);
      if (selectedPlan == null) return {};

      final plan = decodePlan(selectedPlan.content);
      if (plan.isEmpty) return {};

      final savedIntelligence = await StudyResultService.getResult(
        documentId: '${selectedPlan.documentId}_curriculum_intelligence',
        type: 'curriculum_intelligence',
      );

      if (savedIntelligence != null) {
        final savedReport = decodePlan(savedIntelligence.content);
        if (savedReport.isNotEmpty) return savedReport;
      }

      final report = CurriculumIntelligenceEngine.analyzeTeachingPlan(
        plan: plan,
      );

      await AcademicResourceRepository.saveCurriculumIntelligence(
        teachingPlanDocumentId: selectedPlan.documentId,
        content: jsonEncode(report),
      );

      return report;
    } catch (_) {
      return {};
    }
  }

  StudyResult? selectTeachingPlanForCourse(
    List<StudyResult> plans,
    CourseRecord? activeCourse,
  ) {
    if (plans.isEmpty) return null;
    if (activeCourse == null) return plans.first;

    for (final result in plans) {
      final plan = decodePlan(result.content);
      if (planMatchesCourse(plan, activeCourse)) return result;
    }

    return plans.first;
  }

  bool planMatchesCourse(Map<String, dynamic> plan, CourseRecord course) {
    final courseId = plan['course_id']?.toString().trim() ?? '';
    final courseName = plan['course_name']?.toString().trim() ?? '';
    final courseCode = plan['course_code']?.toString().trim() ?? '';
    final displayName = plan['course_display_name']?.toString().trim() ?? '';

    if (courseId.isNotEmpty && courseId == course.id) return true;
    if (courseName.isNotEmpty &&
        courseName.toLowerCase() == course.name.toLowerCase()) {
      return true;
    }
    if (courseCode.isNotEmpty &&
        course.code.isNotEmpty &&
        courseCode.toLowerCase() == course.code.toLowerCase()) {
      return true;
    }
    if (displayName.isNotEmpty &&
        displayName.toLowerCase() == course.displayName.toLowerCase()) {
      return true;
    }

    return false;
  }

  Map<String, dynamic> decodePlan(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    return {};
  }

  Future<void> changeCourse(String? courseId) async {
    if (courseId == null) return;
    await CourseService.setActiveCourse(courseId);
    await loadDashboard();
  }

  double get average {
    final evaluated = summaries.where((item) => item.hasGrades).toList();
    if (evaluated.isEmpty) return 0;
    return evaluated.map((item) => item.average).reduce((a, b) => a + b) /
        evaluated.length;
  }

  double get attendanceAverage {
    final withAttendance =
        summaries.where((item) => item.hasAttendance).toList();
    if (withAttendance.isEmpty) return 0;
    return withAttendance
            .map((item) => item.attendanceRate)
            .reduce((a, b) => a + b) /
        withAttendance.length;
  }

  int get approvedCount =>
      summaries.where((item) => item.hasGrades && item.approved).length;

  int get evaluatedCount => summaries.where((item) => item.hasGrades).length;

  int get notEvaluatedCount =>
      summaries.where((item) => !item.hasGrades).length;

  int get failedCount =>
      summaries.where((item) => item.hasGrades && !item.approved).length;

  double get approvalRate =>
      evaluatedCount == 0 ? 0 : (approvedCount / evaluatedCount) * 100;

  double get failureRate =>
      evaluatedCount == 0 ? 0 : (failedCount / evaluatedCount) * 100;

  double get evaluatedRate =>
      summaries.isEmpty ? 0 : (evaluatedCount / summaries.length) * 100;

  Map<String, int> get gradeDistribution {
    final evaluated = summaries.where((item) => item.hasGrades).toList();

    return {
      'Excelente 90-100': evaluated.where((item) => item.average >= 90).length,
      'Muy bueno 80-89': evaluated
          .where((item) => item.average >= 80 && item.average < 90)
          .length,
      'Aprobado 70-79': evaluated
          .where((item) => item.average >= 70 && item.average < 80)
          .length,
      'Riesgo 60-69': evaluated
          .where((item) => item.average >= 60 && item.average < 70)
          .length,
      'Crítico 0-59': evaluated.where((item) => item.average < 60).length,
    };
  }

  Map<String, int> get attendanceDistribution {
    final data = summaries.where((item) => item.hasAttendance).toList();

    return {
      'Alta 90-100': data.where((item) => item.attendanceRate >= 90).length,
      'Media 80-89': data
          .where(
            (item) => item.attendanceRate >= 80 && item.attendanceRate < 90,
          )
          .length,
      'Baja 70-79': data
          .where(
            (item) => item.attendanceRate >= 70 && item.attendanceRate < 80,
          )
          .length,
      'Crítica <70': data.where((item) => item.attendanceRate < 70).length,
    };
  }

  Map<String, int> get academicStatusDistribution {
    final failed =
        summaries.where((item) => item.hasGrades && !item.approved).length;

    return {
      'Aprobados': approvedCount,
      'En riesgo': failed,
      'Sin evaluar': notEvaluatedCount,
    };
  }

  List<StudentAcademicSummary> get topStudents {
    final data = summaries.where((item) => item.hasGrades).toList();

    data.sort((a, b) {
      final byAverage = b.average.compareTo(a.average);
      if (byAverage != 0) return byAverage;

      final byAttendance = b.attendanceRate.compareTo(a.attendanceRate);
      if (byAttendance != 0) return byAttendance;

      return a.studentName.compareTo(b.studentName);
    });

    return data.take(10).toList();
  }

  List<StudentAcademicSummary> get bottomStudents {
    final data = summaries.where((item) => item.hasGrades).toList();

    data.sort((a, b) {
      final byAverage = a.average.compareTo(b.average);
      if (byAverage != 0) return byAverage;

      final byAttendance = a.attendanceRate.compareTo(b.attendanceRate);
      if (byAttendance != 0) return byAttendance;

      return a.studentName.compareTo(b.studentName);
    });

    return data.take(10).toList();
  }

  List<StudentAcademicSummary> get riskStudents {
    final data = summaries
        .where(
          (item) =>
              (item.hasGrades && item.average < 70) ||
              (item.hasAttendance && item.attendanceRate < 75),
        )
        .toList();
    data.sort((a, b) => a.average.compareTo(b.average));
    return data.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reprobados =
        summaries.where((item) => item.hasGrades && !item.approved).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Académico'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Académico por Curso',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Resumen ejecutivo de rendimiento, asistencia y riesgo académico.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                if (courses.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 380,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue:
                          activeCourseId.isEmpty ? null : activeCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Curso / Sección',
                        border: OutlineInputBorder(),
                      ),
                      items: courses
                          .map(
                            (course) => DropdownMenuItem(
                              value: course.id,
                              child: Text(
                                course.displayName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: changeCourse,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      label: 'Estudiantes',
                      value: summaries.length.toString(),
                      icon: Icons.groups_rounded,
                    ),
                    _MetricCard(
                      label: 'Promedio',
                      value: '${average.toStringAsFixed(1)}%',
                      icon: Icons.analytics_rounded,
                    ),
                    _MetricCard(
                      label: 'Asistencia',
                      value: summaries.any((item) => item.hasAttendance)
                          ? '${attendanceAverage.toStringAsFixed(1)}%'
                          : 'Sin registro',
                      icon: Icons.event_available_rounded,
                    ),
                    _MetricCard(
                      label: 'Evaluados',
                      value: evaluatedCount.toString(),
                      icon: Icons.assignment_turned_in_rounded,
                    ),
                    _MetricCard(
                      label: 'Sin evaluar',
                      value: notEvaluatedCount.toString(),
                      icon: Icons.pending_actions_rounded,
                    ),
                    _MetricCard(
                      label: 'Aprobados',
                      value: approvedCount.toString(),
                      icon: Icons.verified_rounded,
                    ),
                    _MetricCard(
                      label: '% Aprobación',
                      value: '${approvalRate.toStringAsFixed(1)}%',
                      icon: Icons.trending_up_rounded,
                    ),
                    _MetricCard(
                      label: '% Reprobación',
                      value: '${failureRate.toStringAsFixed(1)}%',
                      icon: Icons.trending_down_rounded,
                    ),
                    _MetricCard(
                      label: '% Evaluados',
                      value: '${evaluatedRate.toStringAsFixed(1)}%',
                      icon: Icons.insights_rounded,
                    ),
                    _MetricCard(
                      label: 'En riesgo',
                      value: reprobados.toString(),
                      icon: Icons.warning_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.goNamed('academic-recognition'),
                      icon: const Icon(Icons.emoji_events_rounded),
                      label: const Text('Reconocimientos Académicos'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.goNamed('dashboard'),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Volver al Dashboard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _AcademicIntelligenceSection(
            report: curriculumIntelligence,
            isEmpty: curriculumIntelligenceUnavailable,
          ),
          const SizedBox(height: 20),
          _DashboardChartsSection(
            gradeDistribution: gradeDistribution,
            attendanceDistribution: attendanceDistribution,
            statusDistribution: academicStatusDistribution,
            topStudents: topStudents,
          ),
          const SizedBox(height: 20),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ranking Global Institucional',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Consolidado de todos los cursos registrados en StudyBook AI.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      label: 'Evaluados globales',
                      value: globalRanking.length.toString(),
                      icon: Icons.public_rounded,
                    ),
                    _MetricCard(
                      label: 'Mejor promedio',
                      value: globalRanking.isEmpty
                          ? 'Pendiente'
                          : '${globalRanking.first.average.toStringAsFixed(1)}%',
                      icon: Icons.emoji_events_rounded,
                    ),
                    _MetricCard(
                      label: 'Mejor estudiante',
                      value: globalRanking.isEmpty
                          ? 'Pendiente'
                          : globalRanking.first.studentName,
                      icon: Icons.workspace_premium_rounded,
                    ),
                    _MetricCard(
                      label: 'Top institucional',
                      value: globalRanking.isEmpty
                          ? '0'
                          : globalRanking.take(10).length.toString(),
                      icon: Icons.military_tech_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (globalRanking.isEmpty)
                  const Text(
                    'No hay datos suficientes para ranking global.',
                    style: TextStyle(color: AppTheme.textMuted),
                  )
                else
                  ...globalRanking.take(10).toList().asMap().entries.map(
                    (entry) {
                      final item = entry.value;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('#${entry.key + 1}'),
                        ),
                        title: Text(item.studentName),
                        subtitle: Text(
                          '${item.courseName} · Promedio ${item.average.toStringAsFixed(1)}% · Percentil ${item.percentile.toStringAsFixed(1)}%',
                        ),
                        trailing: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppTheme.accent,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🏆 Cuadro de Honor',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (topStudents.isEmpty)
                  const Text(
                    'No hay estudiantes evaluados.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                    ),
                  )
                else
                  Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          child: Text('🥇'),
                        ),
                        title: Text(topStudents[0].studentName),
                        subtitle: Text(
                          'Promedio ${topStudents[0].average.toStringAsFixed(1)}%',
                        ),
                      ),
                      if (topStudents.length > 1)
                        ListTile(
                          leading: const CircleAvatar(
                            child: Text('🥈'),
                          ),
                          title: Text(topStudents[1].studentName),
                          subtitle: Text(
                            'Promedio ${topStudents[1].average.toStringAsFixed(1)}%',
                          ),
                        ),
                      if (topStudents.length > 2)
                        ListTile(
                          leading: const CircleAvatar(
                            child: Text('🥉'),
                          ),
                          title: Text(topStudents[2].studentName),
                          subtitle: Text(
                            'Promedio ${topStudents[2].average.toStringAsFixed(1)}%',
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _RankingSection(
            title: 'Top 10 Oficial',
            emptyText: 'No hay datos suficientes para ranking.',
            students: topStudents,
          ),
          const SizedBox(height: 14),
          _RankingSection(
            title: 'Bottom 10 Oficial',
            emptyText: 'No hay datos suficientes para ranking inferior.',
            students: bottomStudents,
            riskMode: true,
          ),
          const SizedBox(height: 14),
          _RankingSection(
            title: 'Estudiantes en riesgo',
            emptyText: 'No hay estudiantes en riesgo detectados.',
            students: riskStudents,
            riskMode: true,
          ),
          const SizedBox(height: 14),
          _RankingSection(
            title: 'Todos los estudiantes',
            emptyText: 'No hay estudiantes registrados.',
            students: summaries,
          ),
        ],
      ),
    );
  }
}

class _AcademicIntelligenceSection extends StatelessWidget {
  final Map<String, dynamic> report;
  final bool isEmpty;

  const _AcademicIntelligenceSection({
    required this.report,
    required this.isEmpty,
  });

  String text(dynamic value) => value?.toString().trim() ?? '';

  int intValue(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<dynamic> listValue(dynamic value) {
    return value is List ? value : const [];
  }

  @override
  Widget build(BuildContext context) {
    if (isEmpty || report.isEmpty) {
      return const SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inteligencia Académica',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No hay planificación disponible para analizar.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    final quality = report['quality'] is Map
        ? Map<String, dynamic>.from(report['quality'] as Map)
        : <String, dynamic>{};
    final alerts = listValue(report['alerts']);
    final recommendations = listValue(report['recommendations']);
    final missingResources = listValue(report['missing_resources']);
    final units = listValue(report['units'])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final totalUnits = intValue(report['total_units']);
    final completedUnits = intValue(report['completed_units']);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inteligencia Académica',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Diagnóstico curricular generado desde la planificación y los recursos IA por unidad.',
            style: TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricCard(
                label: 'Cobertura curricular',
                value: '${intValue(report['curriculum_coverage'])}%',
                icon: Icons.auto_graph_rounded,
              ),
              _MetricCard(
                label: 'Puntuación académica',
                value: '${intValue(quality['academic_score'])}%',
                icon: Icons.workspace_premium_rounded,
              ),
              _MetricCard(
                label: 'Calidad evaluación',
                value: '${intValue(quality['assessment_quality'])}%',
                icon: Icons.fact_check_rounded,
              ),
              _MetricCard(
                label: 'Calidad recursos',
                value: '${intValue(quality['resource_quality'])}%',
                icon: Icons.inventory_2_rounded,
              ),
              _MetricCard(
                label: 'Unidades completas',
                value: '$completedUnits / $totalUnits',
                icon: Icons.check_circle_rounded,
              ),
              _MetricCard(
                label: 'Recursos pendientes',
                value: missingResources.length.toString(),
                icon: Icons.pending_actions_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              SizedBox(
                width: 420,
                child: _IntelligenceList(
                  title: 'Alertas',
                  emptyText: 'Sin alertas críticas.',
                  items: alerts.take(3).map(text).toList(),
                ),
              ),
              SizedBox(
                width: 420,
                child: _IntelligenceList(
                  title: 'Recomendaciones',
                  emptyText: 'Sin recomendaciones pendientes.',
                  items: recommendations.take(3).map(text).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Estado por unidad',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (units.isEmpty)
            const Text(
              'No hay unidades disponibles.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            ...units.map((unit) => _UnitStatusRow(unit: unit)),
        ],
      ),
    );
  }
}

class _IntelligenceList extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<String> items;

  const _IntelligenceList({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        if (items.where((item) => item.isNotEmpty).isEmpty)
          Text(
            emptyText,
            style: const TextStyle(color: AppTheme.textMuted),
          )
        else
          ...items.where((item) => item.isNotEmpty).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $item',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _UnitStatusRow extends StatelessWidget {
  final Map<String, dynamic> unit;

  const _UnitStatusRow({required this.unit});

  String text(dynamic value) => value?.toString().trim() ?? '';

  int intValue(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final missing = unit['missing_resources'] is List
        ? List<dynamic>.from(unit['missing_resources'] as List)
        : <dynamic>[];
    final missingLabels = missing
        .map((item) {
          if (item is Map) {
            return text(item['resource_label']).isNotEmpty
                ? text(item['resource_label'])
                : text(item['resource_key']);
          }

          return text(item);
        })
        .where((item) => item.isNotEmpty)
        .toList();
    final progress = intValue(unit['completion_score']);
    final title = text(unit['unit_topic']).isNotEmpty
        ? text(unit['unit_topic'])
        : 'Unidad ${text(unit['week'])}';
    final missingText = missingLabels.isEmpty
        ? 'Completa'
        : 'Falta ${missingLabels.join(', ')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          child: Text('${progress.clamp(0, 100)}%'),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          missingText,
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      ),
    );
  }
}

class _DashboardChartsSection extends StatelessWidget {
  final Map<String, int> gradeDistribution;
  final Map<String, int> attendanceDistribution;
  final Map<String, int> statusDistribution;
  final List<StudentAcademicSummary> topStudents;

  const _DashboardChartsSection({
    required this.gradeDistribution,
    required this.attendanceDistribution,
    required this.statusDistribution,
    required this.topStudents,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        SizedBox(
          width: 360,
          child: _BarChartCard(
            title: 'Distribución de notas',
            subtitle: 'Rangos de rendimiento académico',
            values: gradeDistribution,
          ),
        ),
        SizedBox(
          width: 360,
          child: _BarChartCard(
            title: 'Asistencia',
            subtitle: 'Rangos de participación',
            values: attendanceDistribution,
          ),
        ),
        SizedBox(
          width: 360,
          child: _BarChartCard(
            title: 'Estado académico',
            subtitle: 'Aprobados, riesgo y pendientes',
            values: statusDistribution,
          ),
        ),
        SizedBox(
          width: 360,
          child: _TopVisualCard(
            students: topStudents,
          ),
        ),
      ],
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Map<String, int> values;

  const _BarChartCard({
    required this.title,
    required this.subtitle,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.values.isEmpty
        ? 0
        : values.values.reduce((a, b) => a > b ? a : b);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          if (maxValue == 0)
            const Text(
              'Aún no hay información suficiente para este indicador.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            ...values.entries.map(
              (entry) {
                final ratio = maxValue == 0 ? 0.0 : entry.value / maxValue;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BarRow(
                    label: entry.key,
                    value: entry.value.toString(),
                    ratio: ratio,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TopVisualCard extends StatelessWidget {
  final List<StudentAcademicSummary> students;

  const _TopVisualCard({
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    final data = students.where((item) => item.hasGrades).take(5).toList();

    final maxValue = data.isEmpty
        ? 0.0
        : data.map((item) => item.average).reduce((a, b) => a > b ? a : b);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top visual',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mejores promedios del curso',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const Text(
              'Aún no hay información suficiente para este indicador.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            ...data.map(
              (student) {
                final ratio = maxValue <= 0 ? 0.0 : student.average / maxValue;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BarRow(
                    label: student.studentName,
                    value: '${student.average.toStringAsFixed(1)}%',
                    ratio: ratio,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final String value;
  final double ratio;

  const _BarRow({
    required this.label,
    required this.value,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final safeRatio = ratio.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: safeRatio,
            minHeight: 9,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.accent),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<StudentAcademicSummary> students;
  final bool riskMode;

  const _RankingSection({
    required this.title,
    required this.emptyText,
    required this.students,
    this.riskMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (students.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(color: AppTheme.textMuted),
            )
          else
            ...students.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StudentRankTile(
                      position: entry.key + 1,
                      summary: entry.value,
                      riskMode: riskMode,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _StudentRankTile extends StatelessWidget {
  final int position;
  final StudentAcademicSummary summary;
  final bool riskMode;

  const _StudentRankTile({
    required this.position,
    required this.summary,
    required this.riskMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        context.goNamed(
          'student-profile',
          extra: {
            'studentCode': summary.studentCode,
            'studentName': summary.studentName,
            'courseId': summary.courseId,
            'courseName': summary.courseName,
          },
        );
      },
      leading: CircleAvatar(
        child: Text(position.toString()),
      ),
      title: Text(summary.studentName),
      subtitle: Text(
        '${summary.studentCode} · ${summary.hasGrades ? 'Promedio ${summary.average.toStringAsFixed(1)}%' : 'Sin evaluar'} · ${summary.hasAttendance ? 'Asistencia ${summary.attendanceRate.toStringAsFixed(1)}%' : 'Sin registro de asistencia'}',
      ),
      trailing: Icon(
        riskMode ? Icons.warning_rounded : Icons.star_rounded,
        color: riskMode ? Colors.orange : AppTheme.accent,
      ),
    );
  }
}
