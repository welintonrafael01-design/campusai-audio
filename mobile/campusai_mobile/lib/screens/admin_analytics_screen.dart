import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState
    extends State<AdminAnalyticsScreen> {
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

  Widget buildMetric({
    required IconData icon,
    required String title,
    required dynamic value,
  }) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppTheme.accent,
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPathList() {
    final paths = data?['requests_by_path'];

    if (paths is! Map || paths.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = paths.entries.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(22),
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
          const SizedBox(height: 12),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthScore = data?['health_score'] ?? 100;

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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error.isNotEmpty
                ? Center(
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.25,
                        children: [
                          buildMetric(
                            icon: Icons.favorite_rounded,
                            title: 'Health Score',
                            value: '$healthScore%',
                          ),
                          buildMetric(
                            icon: Icons.timeline_rounded,
                            title: 'Requests',
                            value: data?['total_requests'] ?? 0,
                          ),
                          buildMetric(
                            icon: Icons.picture_as_pdf_rounded,
                            title: 'PDFs',
                            value: data?['pdf_uploads'] ?? 0,
                          ),
                          buildMetric(
                            icon: Icons.chat_rounded,
                            title: 'Chats',
                            value: data?['chat_requests'] ?? 0,
                          ),
                          buildMetric(
                            icon: Icons.style_rounded,
                            title: 'Flashcards',
                            value: data?['flashcards_generated'] ?? 0,
                          ),
                          buildMetric(
                            icon: Icons.quiz_rounded,
                            title: 'Exámenes',
                            value: data?['exams_generated'] ?? 0,
                          ),
                          buildMetric(
                            icon: Icons.file_download_rounded,
                            title: 'Exportaciones',
                            value: data?['exports_generated'] ?? 0,
                          ),
                          buildMetric(
                            icon: Icons.warning_rounded,
                            title: 'Errores',
                            value: data?['errors'] ?? 0,
                          ),
                          buildMetric(
                            icon: Icons.speed_rounded,
                            title: 'Tiempo Promedio',
                            value:
                                '${data?['average_duration_seconds'] ?? 0}s',
                          ),
                          buildMetric(
                            icon: Icons.route_rounded,
                            title: 'Rutas',
                            value: (data?['requests_by_path'] as Map?)
                                    ?.length ??
                                0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      buildPathList(),
                    ],
                  ),
      ),
    );
  }
}
