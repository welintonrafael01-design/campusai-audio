import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../layout/responsive_layout.dart';
import '../services/campus_intelligence/campus_intelligence_models.dart';
import '../services/campus_intelligence/campus_intelligence_service.dart';
import '../services/campus_intelligence/campus_trend_service.dart';
import '../services/learning_engine/achievement_service.dart';
import '../services/learning_engine/learning_analytics_service.dart';
import '../services/learning_engine/learning_models.dart';
import '../services/learning_engine/learning_session_service.dart';
import '../services/learning_engine/recommendation_engine.dart';
import '../services/learning_engine/streak_service.dart';
import '../services/learning_engine/student_intelligence_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final analyticsService = const LearningAnalyticsService();
  final streakService = const StreakService();
  final recommendationEngine = const RecommendationEngine();
  final achievementService = const AchievementService();
  final intelligenceService = const StudentIntelligenceService();
  final sessionService = const LearningSessionService();
  final campusIntelligenceService = const CampusIntelligenceService();
  final campusTrendService = const CampusTrendService();

  bool isLoading = true;
  String errorMessage = '';

  LearningAnalytics analytics = LearningAnalytics.empty;
  ContinueLearningItem continueLearning = ContinueLearningItem.empty;
  LearningStreak streak = LearningStreak.empty;
  List<LearningRecommendation> recommendations = [];
  List<Achievement> achievements = [];
  StudentIntelligence intelligence = StudentIntelligence.empty;
  CampusIntelligenceSnapshot campusSnapshot =
      CampusIntelligenceSnapshot.empty();
  List<CampusTrend> campusTrends = [];
  List<Map<String, dynamic>> recentSessions = [];

  @override
  void initState() {
    super.initState();
    loadStudentDashboard();
  }

  Future<void> loadStudentDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final loadedAnalytics = await analyticsService.buildAnalytics();
      final loadedContinue = await analyticsService.buildContinueLearningItem();
      final loadedStreak = await streakService.calculateStreak();
      final loadedRecommendations =
          await recommendationEngine.generateRecommendations();
      final loadedAchievements = await achievementService.getAchievements();
      final loadedIntelligence = await intelligenceService.analyzeStudent();
      final loadedSessions = await sessionService.getSessions();
      final loadedCampusSnapshot =
          await campusIntelligenceService.buildSnapshot();
      final loadedCampusTrends = await campusTrendService.buildTrends();

      if (!mounted) return;

      setState(() {
        analytics = loadedAnalytics;
        continueLearning = loadedContinue;
        streak = loadedStreak;
        recommendations = loadedRecommendations;
        achievements = loadedAchievements;
        intelligence = loadedIntelligence;
        campusSnapshot = loadedCampusSnapshot;
        campusTrends = loadedCampusTrends;
        recentSessions = loadedSessions.take(6).toList();
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'No se pudo cargar Learning Engine.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Aprendizaje'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadStudentDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(isMobile: isMobile),
                          if (errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _ErrorCard(message: errorMessage),
                          ],
                          const SizedBox(height: 18),
                          _ContinueLearningCard(
                            item: continueLearning,
                            onContinue: continueLearning.hasProgress
                                ? () => context.goNamed(
                                      'audioBookStudio',
                                      extra: {
                                        'sourceMode': 'solo',
                                        'sourceType': 'text',
                                      },
                                    )
                                : null,
                          ),
                          const SizedBox(height: 18),
                          _MetricsGrid(analytics: analytics),
                          const SizedBox(height: 18),
                          _CampusIntelligenceCard(snapshot: campusSnapshot),
                          const SizedBox(height: 18),
                          _CampusTrendsCard(
                            trends: campusTrends,
                            latestSnapshot: campusSnapshot,
                          ),
                          const SizedBox(height: 18),
                          _ResponsivePair(
                            left: _StreakCard(streak: streak),
                            right: _RecommendationsCard(
                              recommendations: recommendations,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _ResponsivePair(
                            left: _AchievementsCard(
                              achievements: achievements,
                            ),
                            right: _StudentIntelligenceCard(
                              intelligence: intelligence,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _RecentSessionsCard(sessions: recentSessions),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isMobile;

  const _Header({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mi Aprendizaje',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: isMobile ? 30 : 42,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Continúa tu progreso con StudyBook AI',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => context.goNamed('voiceTutor'),
          icon: const Icon(Icons.record_voice_over_rounded),
          label: const Text('Tutor IA'),
        ),
      ],
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final ContinueLearningItem item;
  final VoidCallback? onContinue;

  const _ContinueLearningCard({
    required this.item,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: item.hasProgress
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  title: 'Continuar aprendiendo',
                  icon: Icons.play_circle_fill_rounded,
                  color: AppTheme.accent,
                ),
                const SizedBox(height: 14),
                Text(
                  item.audiobookTitle,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.chapterTitle,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: item.progressPercentage / 100,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${item.progressPercentage}% completado',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: onContinue,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Continuar'),
                    ),
                  ],
                ),
              ],
            )
          : const _EmptyState(
              icon: Icons.auto_stories_rounded,
              title: 'Continuar aprendiendo',
              message: 'Aún no has iniciado una sesión de aprendizaje.',
            ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final LearningAnalytics analytics;

  const _MetricsGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return GridView.count(
      crossAxisCount: isDesktop ? 3 : (isMobile ? 2 : 3),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: isMobile ? 1.12 : 1.85,
      children: [
        _MetricCard(
          title: 'Tiempo estudiado',
          value: '${analytics.studyMinutes} min',
          icon: Icons.schedule_rounded,
          color: AppTheme.primary,
        ),
        _MetricCard(
          title: 'Sesiones',
          value: '${analytics.sessions}',
          icon: Icons.bolt_rounded,
          color: AppTheme.accent,
        ),
        _MetricCard(
          title: 'Capítulos completados',
          value: '${analytics.completedChapters}',
          icon: Icons.menu_book_rounded,
          color: AppTheme.success,
        ),
        _MetricCard(
          title: 'Dominio promedio',
          value: '${analytics.masteryPercentage}%',
          icon: Icons.insights_rounded,
          color: AppTheme.secondary,
        ),
        _MetricCard(
          title: 'Quiz completados',
          value: '${analytics.quizCompleted}',
          icon: Icons.quiz_rounded,
          color: AppTheme.warning,
        ),
        _MetricCard(
          title: 'Flashcards estudiadas',
          value: '${analytics.flashcardsStudied}',
          icon: Icons.style_rounded,
          color: AppTheme.danger,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CampusIntelligenceCard extends StatelessWidget {
  final CampusIntelligenceSnapshot snapshot;

  const _CampusIntelligenceCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Inteligencia CampusAI',
            icon: Icons.hub_rounded,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 14),
          Text(
            snapshot.recommendedNextAction,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Chip(label: Text('Riesgo: ${snapshot.academicRisk}')),
              Chip(label: Text('Dominio: ${snapshot.masteryScore}%')),
              Chip(label: Text('Engagement: ${snapshot.engagementScore}%')),
              Chip(label: Text('Score: ${snapshot.studentScore}%')),
            ],
          ),
          const SizedBox(height: 12),
          if (snapshot.alerts.isEmpty)
            const Text(
              'Sin alertas críticas.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            _ChipGroup(
              title: 'Alertas principales',
              values: snapshot.alerts.take(3).toList(),
            ),
        ],
      ),
    );
  }
}

class _CampusTrendsCard extends StatelessWidget {
  final List<CampusTrend> trends;
  final CampusIntelligenceSnapshot latestSnapshot;

  const _CampusTrendsCard({
    required this.trends,
    required this.latestSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    final mastery = _trendFor('Dominio');
    final engagement = _trendFor('Engagement');
    final risk = _trendFor('Riesgo');
    final score = _trendFor('Score general');

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Tendencias',
            icon: Icons.trending_up_rounded,
            color: AppTheme.secondary,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            label: 'Último snapshot',
            value: _formatDate(latestSnapshot.generatedAt),
          ),
          if (score != null)
            _InfoRow(
              label: 'Comparación anterior',
              value: _deltaLabel(score, suffix: '%'),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (mastery != null)
                _TrendChip(trend: mastery, label: 'Dominio', suffix: '%'),
              if (engagement != null)
                _TrendChip(
                  trend: engagement,
                  label: 'Engagement',
                  suffix: '%',
                ),
              if (risk != null) _TrendChip(trend: risk, label: 'Riesgo'),
            ],
          ),
          const SizedBox(height: 12),
          if (trends.isEmpty)
            const Text(
              'Aún no hay historial suficiente para calcular tendencias.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            for (final trend in trends.take(4))
              _ListItem(
                title: trend.metric,
                subtitle: trend.description,
                icon: _trendIcon(trend.direction),
              ),
        ],
      ),
    );
  }

  CampusTrend? _trendFor(String metric) {
    final cleanMetric = metric.trim().toLowerCase();
    for (final trend in trends) {
      if (trend.metric.trim().toLowerCase() == cleanMetric) return trend;
    }
    return null;
  }

  String _deltaLabel(CampusTrend trend, {String suffix = ''}) {
    if (trend.previousValue <= 0) return 'Sin snapshot anterior';
    final sign = trend.delta > 0 ? '+' : '';
    return '$sign${_formatTrendNumber(trend.delta)}$suffix';
  }

  IconData _trendIcon(String direction) {
    if (direction == 'up') return Icons.trending_up_rounded;
    if (direction == 'down') return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }
}

class _TrendChip extends StatelessWidget {
  final CampusTrend trend;
  final String label;
  final String suffix;

  const _TrendChip({
    required this.trend,
    required this.label,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final icon = trend.direction == 'up'
        ? Icons.arrow_upward_rounded
        : trend.direction == 'down'
            ? Icons.arrow_downward_rounded
            : Icons.remove_rounded;
    final color = trend.direction == 'up'
        ? AppTheme.success
        : trend.direction == 'down'
            ? AppTheme.warning
            : AppTheme.textMuted;

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        '$label: ${_formatTrendNumber(trend.currentValue)}$suffix',
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final LearningStreak streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Racha',
            icon: Icons.local_fire_department_rounded,
            color: AppTheme.warning,
          ),
          const SizedBox(height: 16),
          _InfoRow(
              label: 'Racha actual', value: '${streak.currentStreakDays} días'),
          _InfoRow(
              label: 'Mejor racha', value: '${streak.bestStreakDays} días'),
          _InfoRow(
            label: 'Último estudio',
            value: _formatDate(streak.lastStudyDate),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  final List<LearningRecommendation> recommendations;

  const _RecommendationsCard({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Recomendaciones',
            icon: Icons.tips_and_updates_rounded,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 12),
          if (recommendations.isEmpty)
            const Text(
              'No hay recomendaciones pendientes.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            for (final recommendation in recommendations.take(4))
              _ListItem(
                title: recommendation.title,
                subtitle: recommendation.description,
                icon: Icons.arrow_right_rounded,
              ),
        ],
      ),
    );
  }
}

class _AchievementsCard extends StatelessWidget {
  final List<Achievement> achievements;

  const _AchievementsCard({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Logros',
            icon: Icons.emoji_events_rounded,
            color: AppTheme.warning,
          ),
          const SizedBox(height: 14),
          if (achievements.isEmpty)
            const Text(
              'Completa tu primera sesión para desbloquear logros.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final achievement in achievements)
                  _AchievementBadge(achievement: achievement),
              ],
            ),
        ],
      ),
    );
  }
}

class _StudentIntelligenceCard extends StatelessWidget {
  final StudentIntelligence intelligence;

  const _StudentIntelligenceCard({required this.intelligence});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Student Intelligence',
            icon: Icons.psychology_rounded,
            color: AppTheme.secondary,
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'Nivel', value: intelligence.level),
          _InfoRow(label: 'Riesgo', value: intelligence.risk),
          const SizedBox(height: 12),
          _ChipGroup(title: 'Fortalezas', values: intelligence.strengths),
          _ChipGroup(title: 'Debilidades', values: intelligence.weaknesses),
          _ChipGroup(
            title: 'Competencias fuertes',
            values: intelligence.strongCompetencies,
          ),
          _ChipGroup(
            title: 'Competencias débiles',
            values: intelligence.weakCompetencies,
          ),
        ],
      ),
    );
  }
}

class _RecentSessionsCard extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;

  const _RecentSessionsCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Historial reciente',
            icon: Icons.history_rounded,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            const Text(
              'No hay sesiones recientes.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            for (final session in sessions)
              _ListItem(
                title: _cleanText(session['audiobook_id']).isEmpty
                    ? 'Sesión de aprendizaje'
                    : _cleanText(session['audiobook_id']),
                subtitle:
                    '${_formatDate(_dateFrom(session['ended_at']))} · ${_durationLabel(session['duration_seconds'])} · ${_cleanText(session['chapter_id']).isEmpty ? 'Capítulo' : _cleanText(session['chapter_id'])} · Quiz ${_quizLabel(session)} · ${_intFrom(session['flashcards_viewed'])} flashcards',
                icon: Icons.play_lesson_rounded,
              ),
        ],
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _ResponsivePair({
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isMobile(context)) {
      return Column(
        children: [
          left,
          const SizedBox(height: 18),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 18),
        Expanded(child: right),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ListItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final color = achievement.unlocked ? AppTheme.warning : AppTheme.textMuted;

    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: achievement.unlocked ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            achievement.unlocked
                ? Icons.emoji_events_rounded
                : Icons.lock_outline_rounded,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${achievement.progress}/${achievement.target}',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final String title;
  final List<String> values;

  const _ChipGroup({
    required this.title,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                Chip(
                  label: Text(value),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  labelStyle: const TextStyle(color: AppTheme.textPrimary),
                  side: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.18),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, icon: icon, color: AppTheme.accent),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Sin registro';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _durationLabel(dynamic seconds) {
  final minutes = (_intFrom(seconds) / 60).round();
  if (minutes <= 0) return '0 min';
  return '$minutes min';
}

String _formatTrendNumber(double value) {
  if (value % 1 == 0) return value.round().toString();
  return value.toStringAsFixed(1);
}

String _quizLabel(Map<String, dynamic> session) {
  final score = _intFrom(session['quiz_score']);
  final total = _intFrom(session['quiz_total']);
  if (total <= 0) return 'sin quiz';
  return '$score/$total';
}

DateTime? _dateFrom(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '');
}

String _cleanText(dynamic value) {
  return value?.toString().trim() ?? '';
}

int _intFrom(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
