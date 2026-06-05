import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool isLoading = true;
  String error = '';
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final result = await AnalyticsService.getSummary();

      if (!mounted) return;

      setState(() {
        data = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _durationLabel(dynamic value) {
    final seconds = _asDouble(value);

    if (seconds <= 0) return '0s';
    if (seconds < 1) return '${seconds.toStringAsFixed(2)}s';
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';

    final minutes = seconds / 60;
    return '${minutes.toStringAsFixed(1)}m';
  }

  int _gridColumns(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 650) return 3;
    return 2;
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: AppTheme.accent,
              size: 24,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final healthScore = _asInt(data?['health_score']);
    final errors = _asInt(data?['errors']);
    final avgDuration = _asDouble(data?['average_duration_seconds']);

    String statusTitle = 'Sistema estable';
    String statusMessage = 'El sistema no presenta señales críticas.';
    IconData statusIcon = Icons.verified_rounded;

    if (healthScore < 70 || errors > 10) {
      statusTitle = 'Revisión recomendada';
      statusMessage =
          'Hay errores o señales de bajo rendimiento que deben revisarse.';
      statusIcon = Icons.warning_rounded;
    } else if (avgDuration > 5) {
      statusTitle = 'Rendimiento moderado';
      statusMessage =
          'El tiempo promedio de respuesta está algo elevado.';
      statusIcon = Icons.speed_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.accent.withValues(alpha: 0.14),
            child: Icon(
              statusIcon,
              color: AppTheme.accent,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusMessage,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$healthScore%',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathList() {
    final paths = data?['requests_by_path'];

    if (paths is! Map || paths.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Text(
          'Todavía no hay rutas registradas.',
          style: TextStyle(
            color: AppTheme.textMuted,
          ),
        ),
      );
    }

    final entries = paths.entries.toList()
      ..sort((a, b) {
        final aValue = _asInt(a.value);
        final bValue = _asInt(b.value);
        return bValue.compareTo(aValue);
      });

    final topEntries = entries.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top rutas',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rutas con mayor cantidad de solicitudes.',
            style: TextStyle(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          ...topEntries.map(
            (entry) {
              final count = _asInt(entry.value);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.accent,
              size: 46,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar Analytics',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final totalRequests = _asInt(data?['total_requests']);
    final pdfUploads = _asInt(data?['pdf_uploads']);
    final chatRequests = _asInt(data?['chat_requests']);
    final flashcardsGenerated = _asInt(data?['flashcards_generated']);
    final examsGenerated = _asInt(data?['exams_generated']);
    final exportsGenerated = _asInt(data?['exports_generated']);
    final errorsCount = _asInt(data?['errors']);
    final healthScore = _asInt(data?['health_score']);
    final routesCount = (data?['requests_by_path'] as Map?)?.length ?? 0;
    final averageDuration =
        _durationLabel(data?['average_duration_seconds']);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _gridColumns(constraints.maxWidth);

        return RefreshIndicator(
          onRefresh: loadData,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _sectionTitle(
                'Analytics Dashboard v2',
                subtitle:
                    'Resumen operativo de CampusAI: uso, rendimiento, módulos y rutas principales.',
              ),
              const SizedBox(height: 20),
              _buildStatusCard(),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.15,
                children: [
                  _buildMetric(
                    icon: Icons.favorite_rounded,
                    title: 'Health Score',
                    value: '$healthScore%',
                    subtitle: 'Estado general',
                  ),
                  _buildMetric(
                    icon: Icons.timeline_rounded,
                    title: 'Requests',
                    value: totalRequests.toString(),
                    subtitle: 'Solicitudes totales',
                  ),
                  _buildMetric(
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'PDFs',
                    value: pdfUploads.toString(),
                    subtitle: 'Documentos procesados',
                  ),
                  _buildMetric(
                    icon: Icons.chat_rounded,
                    title: 'Chats',
                    value: chatRequests.toString(),
                    subtitle: 'Consultas IA',
                  ),
                  _buildMetric(
                    icon: Icons.style_rounded,
                    title: 'Flashcards',
                    value: flashcardsGenerated.toString(),
                    subtitle: 'Generadas',
                  ),
                  _buildMetric(
                    icon: Icons.quiz_rounded,
                    title: 'Exámenes',
                    value: examsGenerated.toString(),
                    subtitle: 'Generados',
                  ),
                  _buildMetric(
                    icon: Icons.file_download_rounded,
                    title: 'Exportaciones',
                    value: exportsGenerated.toString(),
                    subtitle: 'Reportes/archivos',
                  ),
                  _buildMetric(
                    icon: Icons.warning_rounded,
                    title: 'Errores',
                    value: errorsCount.toString(),
                    subtitle: 'Eventos fallidos',
                  ),
                  _buildMetric(
                    icon: Icons.speed_rounded,
                    title: 'Tiempo promedio',
                    value: averageDuration,
                    subtitle: 'Respuesta API',
                  ),
                  _buildMetric(
                    icon: Icons.route_rounded,
                    title: 'Rutas',
                    value: routesCount.toString(),
                    subtitle: 'Endpoints usados',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPathList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('CampusAI Analytics'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: isLoading ? null : loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? _buildErrorState()
              : _buildDashboard(),
    );
  }
}
