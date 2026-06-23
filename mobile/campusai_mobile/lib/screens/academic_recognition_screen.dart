import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../services/academic_analytics_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

String _recognitionLabel(String type) {
  final clean = type.trim().toLowerCase();

  return switch (clean) {
    'gold_medal' => 'Medalla Oro',
    'silver_medal' => 'Medalla Plata',
    'bronze_medal' => 'Medalla Bronce',
    'excellence' => 'Excelencia Académica',
    'honor' => 'Honor Académico',
    'badge' => 'Insignia Académica',
    'certificate' => 'Certificado Académico',
    _ => 'Reconocimiento Académico',
  };
}

IconData _recognitionIcon(String type) {
  final clean = type.trim().toLowerCase();

  return switch (clean) {
    'gold_medal' => Icons.military_tech_rounded,
    'silver_medal' => Icons.workspace_premium_rounded,
    'bronze_medal' => Icons.emoji_events_rounded,
    'excellence' => Icons.auto_awesome_rounded,
    'honor' => Icons.emoji_events_rounded,
    'badge' => Icons.verified_rounded,
    'certificate' => Icons.school_rounded,
    _ => Icons.verified_rounded,
  };
}

class AcademicRecognitionScreen extends StatefulWidget {
  const AcademicRecognitionScreen({super.key});

  @override
  State<AcademicRecognitionScreen> createState() =>
      _AcademicRecognitionScreenState();
}

class _AcademicRecognitionScreenState extends State<AcademicRecognitionScreen> {
  bool loading = true;
  List<StudentRanking> ranking = [];
  List<Map<String, dynamic>> recognitions = [];

  @override
  void initState() {
    super.initState();
    loadRanking();
  }

  Future<void> loadRanking() async {
    final data = await AcademicAnalyticsService.buildGlobalRanking();
    final history = await loadRecognitionHistory();

    if (!mounted) return;

    setState(() {
      ranking = data;
      recognitions = history;
      loading = false;
    });
  }

  Future<List<Map<String, dynamic>>> loadRecognitionHistory() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/certificates/list'),
            headers: AuthService.authHeaders,
          )
          .timeout(ApiService.timeoutDuration);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return [];
      }

      final decoded = jsonDecode(response.body);
      final raw = decoded is Map ? decoded['certificates'] : null;

      if (raw is! List) return [];

      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String recognitionLabel(String type) {
    return switch (type) {
      'excellence' => 'Excelencia Académica',
      'honor' => 'Honor Académico',
      'gold_medal' => 'Medalla Oro',
      'silver_medal' => 'Medalla Plata',
      'bronze_medal' => 'Medalla Bronce',
      'badge' => 'Insignia Académica',
      _ => 'Certificado Académico',
    };
  }

  List<Map<String, dynamic>> get automaticRecognitionRows {
    final rows = <Map<String, dynamic>>[];

    for (final item in ranking) {
      if (item.rank == 1) {
        rows.add(_recognitionRow(item, 'gold_medal'));
      } else if (item.rank == 2) {
        rows.add(_recognitionRow(item, 'silver_medal'));
      } else if (item.rank == 3) {
        rows.add(_recognitionRow(item, 'bronze_medal'));
      }

      if (item.average >= 90) {
        rows.add(_recognitionRow(item, 'excellence'));
      } else if (item.average >= 85) {
        rows.add(_recognitionRow(item, 'honor'));
      }
    }

    return rows;
  }

  Map<String, dynamic> _recognitionRow(
    StudentRanking item,
    String type,
  ) {
    return {
      'student_name': item.studentName,
      'student_code': item.studentCode,
      'course_name': item.courseName,
      'average': '${item.average.toStringAsFixed(1)}%',
      'period': recognitionLabel(type),
      'recognition_type': type,
    };
  }

  Future<void> saveAutomaticRecognitions() async {
    final rows = automaticRecognitionRows;

    if (rows.isEmpty) return;

    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/certificates/auto-recognitions'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode({
            'recognitions': rows,
          }),
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudieron registrar reconocimientos automáticos.');
    }

    final history = await loadRecognitionHistory();

    if (!mounted) return;

    setState(() {
      recognitions = history;
    });
  }

  List<StudentRanking> get honorBoard {
    return ranking.where((item) => item.average >= 85).take(10).toList();
  }

  List<StudentRanking> get excellence {
    return ranking.where((item) => item.average >= 90).take(20).toList();
  }

  List<StudentRanking> get risk {
    return ranking
        .where((item) => item.average < 70)
        .toList()
        .reversed
        .take(20)
        .toList();
  }

  double get averageTop10 {
    final top = ranking.take(10).toList();
    if (top.isEmpty) return 0;

    return top.map((item) => item.average).reduce((a, b) => a + b) / top.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconocimientos Académicos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Portal de Reconocimientos Académicos',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cuadro de honor, ranking global, excelencia académica, certificados e insignias institucionales.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                if (loading)
                  const LinearProgressIndicator()
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetricCard(
                        label: 'Evaluados globales',
                        value: ranking.length.toString(),
                        icon: Icons.public_rounded,
                      ),
                      _MetricCard(
                        label: 'Excelencia >= 90',
                        value: excellence.length.toString(),
                        icon: Icons.workspace_premium_rounded,
                      ),
                      _MetricCard(
                        label: 'Cuadro de honor',
                        value: honorBoard.length.toString(),
                        icon: Icons.emoji_events_rounded,
                      ),
                      _MetricCard(
                        label: 'Promedio Top 10',
                        value: '${averageTop10.toStringAsFixed(1)}%',
                        icon: Icons.trending_up_rounded,
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => context.goNamed('academic-dashboard'),
                  icon: const Icon(Icons.analytics_rounded),
                  label: const Text('Volver al Dashboard Académico'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _RankingCard(
            title: '🏆 Cuadro de Honor Global',
            emptyText: 'No hay estudiantes con promedio igual o superior a 85.',
            students: honorBoard,
            showCertificate: false,
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Ejecutivo Institucional',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Indicadores consolidados para dirección académica.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      label: 'Total evaluados',
                      value: ranking.length.toString(),
                      icon: Icons.groups_rounded,
                    ),
                    _MetricCard(
                      label: 'Excelencia académica',
                      value: excellence.length.toString(),
                      icon: Icons.workspace_premium_rounded,
                    ),
                    _MetricCard(
                      label: 'Cuadro de honor',
                      value: honorBoard.length.toString(),
                      icon: Icons.emoji_events_rounded,
                    ),
                    _MetricCard(
                      label: 'Riesgo académico',
                      value: risk.length.toString(),
                      icon: Icons.warning_rounded,
                    ),
                    _MetricCard(
                      label: 'Reconocimientos',
                      value: recognitions.length.toString(),
                      icon: Icons.verified_rounded,
                    ),
                    _MetricCard(
                      label: 'Promedio Top 10',
                      value: '${averageTop10.toStringAsFixed(1)}%',
                      icon: Icons.trending_up_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reconocimiento Automático',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Genera automáticamente excelencia, honor y medallas institucionales según ranking.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      label: 'Automáticos',
                      value: automaticRecognitionRows.length.toString(),
                      icon: Icons.auto_awesome_rounded,
                    ),
                    _MetricCard(
                      label: 'Medallas Top 3',
                      value: automaticRecognitionRows
                          .where((item) => item['recognition_type']
                              .toString()
                              .contains('medal'))
                          .length
                          .toString(),
                      icon: Icons.military_tech_rounded,
                    ),
                    _MetricCard(
                      label: 'Honores',
                      value: automaticRecognitionRows
                          .where((item) =>
                              item['recognition_type'].toString() == 'honor')
                          .length
                          .toString(),
                      icon: Icons.emoji_events_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: automaticRecognitionRows.isEmpty
                      ? null
                      : () async {
                          try {
                            await saveAutomaticRecognitions();

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Reconocimientos automáticos registrados.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error.toString()),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Registrar reconocimientos automáticos'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cuadro de Honor Oficial',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reporte institucional imprimible con estudiantes destacados.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: honorBoard.isEmpty
                          ? null
                          : () {
                              final rows = honorBoard
                                  .map(
                                    (item) => {
                                      'rank': item.rank,
                                      'student_code': item.studentCode,
                                      'student_name': item.studentName,
                                      'course_name': item.courseName,
                                      'average':
                                          item.average.toStringAsFixed(1),
                                      'percentile':
                                          item.percentile.toStringAsFixed(1),
                                      'attendance': item.attendanceRate
                                          .toStringAsFixed(1),
                                    },
                                  )
                                  .toList();

                              ExportService.exportRowsToXlsx(
                                title: 'studybook_cuadro_honor_oficial',
                                rows: rows,
                              );
                            },
                      icon: const Icon(Icons.grid_on_rounded),
                      label: const Text('Exportar Excel'),
                    ),
                    OutlinedButton.icon(
                      onPressed: honorBoard.isEmpty
                          ? null
                          : () {
                              final content = honorBoard
                                  .map(
                                    (item) =>
                                        '#${item.rank} - ${item.studentName}\n'
                                        'Código: ${item.studentCode}\n'
                                        'Curso: ${item.courseName}\n'
                                        'Promedio: ${item.average.toStringAsFixed(1)}%\n'
                                        'Percentil: ${item.percentile.toStringAsFixed(1)}%\n'
                                        'Asistencia: ${item.attendanceRate.toStringAsFixed(1)}%',
                                  )
                                  .join(
                                    '\n\n-----------------------------\n\n',
                                  );

                              ExportService.exportTextToPdf(
                                title: 'Cuadro de Honor Oficial StudyBook AI',
                                content: content,
                              );
                            },
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Exportar PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _RankingCard(
            title: '🌟 Certificados de Excelencia',
            emptyText: 'No hay estudiantes con promedio igual o superior a 90.',
            students: excellence,
            showCertificate: true,
          ),
          const SizedBox(height: 14),
          _RankingCard(
            title: '🥇 Top 10 Institucional',
            emptyText: 'No hay ranking global disponible.',
            students: ranking.take(10).toList(),
            showCertificate: false,
          ),
          const SizedBox(height: 14),
          _RecognitionHistoryCard(recognitions: recognitions),
          const SizedBox(height: 14),
          _RankingCard(
            title: '⚠️ Riesgo Académico Global',
            emptyText: 'No hay estudiantes en riesgo académico global.',
            students: risk,
            riskMode: true,
            showCertificate: false,
          ),
        ],
      ),
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
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
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

class _RecognitionHistoryCard extends StatefulWidget {
  final List<Map<String, dynamic>> recognitions;

  const _RecognitionHistoryCard({
    required this.recognitions,
  });

  @override
  State<_RecognitionHistoryCard> createState() =>
      _RecognitionHistoryCardState();
}

class _RecognitionHistoryCardState extends State<_RecognitionHistoryCard> {
  String selectedFilter = 'all';

  List<Map<String, dynamic>> get filteredRecognitions {
    if (selectedFilter == 'all') return widget.recognitions;

    if (selectedFilter == 'medals') {
      return widget.recognitions.where((item) {
        final type = '${item['recognition_type'] ?? ''}';
        return type.contains('medal');
      }).toList();
    }

    return widget.recognitions.where((item) {
      return '${item['recognition_type'] ?? 'certificate'}' == selectedFilter;
    }).toList();
  }

  Map<String, int> get stats {
    final data = <String, int>{
      'gold_medal': 0,
      'silver_medal': 0,
      'bronze_medal': 0,
      'excellence': 0,
      'honor': 0,
      'badge': 0,
      'certificate': 0,
    };

    for (final item in widget.recognitions) {
      final type = '${item['recognition_type'] ?? 'certificate'}';
      data[type] = (data[type] ?? 0) + 1;
    }

    return data;
  }

  int get maxStat {
    if (stats.values.isEmpty) return 1;
    final max = stats.values.reduce((a, b) => a > b ? a : b);
    return max == 0 ? 1 : max;
  }

  List<Widget> get filterChips {
    final filters = [
      ('all', 'Todos'),
      ('medals', 'Medallas'),
      ('gold_medal', 'Oro'),
      ('silver_medal', 'Plata'),
      ('bronze_medal', 'Bronce'),
      ('excellence', 'Excelencia'),
      ('honor', 'Honor'),
      ('certificate', 'Certificados'),
      ('badge', 'Insignias'),
    ];

    return filters.map((entry) {
      final selected = selectedFilter == entry.$1;

      return ChoiceChip(
        selected: selected,
        label: Text(entry.$2),
        onSelected: (_) {
          setState(() {
            selectedFilter = entry.$1;
          });
        },
      );
    }).toList();
  }

  String _historyPdfContent() {
    final total = widget.recognitions.length;
    final summary = 'RESUMEN EJECUTIVO\n'
        'Total reconocimientos: $total\n'
        'Medalla Oro: ${stats['gold_medal'] ?? 0}\n'
        'Medalla Plata: ${stats['silver_medal'] ?? 0}\n'
        'Medalla Bronce: ${stats['bronze_medal'] ?? 0}\n'
        'Excelencia Académica: ${stats['excellence'] ?? 0}\n'
        'Honor Académico: ${stats['honor'] ?? 0}\n'
        'Certificados Académicos: ${stats['certificate'] ?? 0}\n'
        'Insignias Académicas: ${stats['badge'] ?? 0}';

    final detail = filteredRecognitions.map(
      (item) {
        final type = _recognitionLabel(
          '${item['recognition_type'] ?? 'certificate'}',
        );

        return 'Tipo: $type\n'
            'Código: ${item['certificate_id'] ?? ''}\n'
            'Estudiante: ${item['student_name'] ?? ''}\n'
            'Matrícula: ${item['student_code'] ?? ''}\n'
            'Curso: ${item['course_name'] ?? ''}\n'
            'Promedio: ${item['average'] ?? ''}\n'
            'Estado: ${item['status'] ?? ''}\n'
            'Fecha: ${item['issued_at'] ?? ''}';
      },
    ).join('\n\n-----------------------------\n\n');

    return '$summary\n\n-----------------------------\n\n$detail';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredRecognitions;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial de Reconocimientos Emitidos',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mostrando ${filtered.length} de ${widget.recognitions.length} reconocimientos.',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          if (widget.recognitions.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filterChips,
            ),
            const SizedBox(height: 14),
            _RecognitionStatsChart(stats: stats, maxStat: maxStat),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Generando Excel del historial...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    await ExportService.exportRowsToXlsx(
                      title: 'studybook_historial_reconocimientos',
                      rows: filtered,
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Excel descargado correctamente.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.grid_on_rounded),
                  label: const Text('Exportar Excel'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Generando PDF del historial...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    await ExportService.exportTextToPdf(
                      title: 'Historial de Reconocimientos',
                      content: _historyPdfContent(),
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PDF descargado correctamente.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Exportar PDF'),
                ),
              ],
            ),
          ],
          if (widget.recognitions.isNotEmpty) const SizedBox(height: 12),
          if (widget.recognitions.isEmpty)
            const Text(
              'Aún no hay certificados o insignias emitidas.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else if (filtered.isEmpty)
            const Text(
              'No hay reconocimientos para el filtro seleccionado.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            ...filtered.take(30).map(
              (item) {
                final type = '${item['recognition_type'] ?? 'certificate'}';

                return ListTile(
                  leading: Icon(
                    _recognitionIcon(type),
                    color: AppTheme.accent,
                  ),
                  title: Text('${item['student_name'] ?? ''}'),
                  subtitle: Text(
                    '${_recognitionLabel(type)} · ${item['certificate_id'] ?? ''} · ${item['course_name'] ?? ''} · Promedio ${item['average'] ?? ''}',
                  ),
                  trailing: Text(
                    '${item['status'] ?? 'valid'}',
                    style: const TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RecognitionStatsChart extends StatelessWidget {
  final Map<String, int> stats;
  final int maxStat;

  const _RecognitionStatsChart({
    required this.stats,
    required this.maxStat,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('gold_medal', 'Medalla Oro'),
      ('silver_medal', 'Medalla Plata'),
      ('bronze_medal', 'Medalla Bronce'),
      ('excellence', 'Excelencia'),
      ('honor', 'Honor'),
      ('certificate', 'Certificados'),
      ('badge', 'Insignias'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribución de reconocimientos',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...rows.map(
          (entry) {
            final value = stats[entry.$1] ?? 0;
            final percent = maxStat == 0 ? 0.0 : value / maxStat;

            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 145,
                    child: Text(
                      entry.$2,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 9,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 30,
                    child: Text(
                      value.toString(),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<StudentRanking> students;
  final bool riskMode;
  final bool showCertificate;

  const _RankingCard({
    required this.title,
    required this.emptyText,
    required this.students,
    this.riskMode = false,
    this.showCertificate = false,
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
            ...students.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('#${item.rank}'),
                  ),
                  title: Text(item.studentName),
                  subtitle: Text(
                    '${item.courseName} · Promedio ${item.average.toStringAsFixed(1)}% · Percentil ${item.percentile.toStringAsFixed(1)}%',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      Icon(
                        riskMode
                            ? Icons.warning_rounded
                            : Icons.emoji_events_rounded,
                        color: riskMode ? Colors.orange : AppTheme.accent,
                      ),
                      if (showCertificate) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            ExportService.exportCertificateToPdf(
                              studentName: item.studentName,
                              studentCode: item.studentCode,
                              courseName: item.courseName,
                              average: '${item.average.toStringAsFixed(1)}%',
                              certificateTitle:
                                  'CERTIFICADO DE EXCELENCIA ACADÉMICA',
                            );
                          },
                          icon: const Icon(Icons.card_membership_rounded),
                          label: const Text('Certificado'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            ExportService.exportAcademicBadgeToPdf(
                              studentName: item.studentName,
                              studentCode: item.studentCode,
                              courseName: item.courseName,
                              average: '${item.average.toStringAsFixed(1)}%',
                              badgeTitle: 'Excelencia Académica',
                            );
                          },
                          icon: const Icon(Icons.military_tech_rounded),
                          label: const Text('Insignia'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
