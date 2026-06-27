import 'package:flutter/material.dart';
import '../services/gamification/gamification_models.dart';
import '../services/institution/institution_models.dart';
import '../services/marketplace/marketplace_models.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';

class XpCard extends StatelessWidget {
  final XP xp;
  const XpCard({super.key, required this.xp});
  @override
  Widget build(BuildContext c) => _Card('Progreso XP', Icons.bolt_rounded,
      '${xp.total} XP · ${xp.earnedToday} ganados hoy');
}

class CurrentLevelWidget extends StatelessWidget {
  final Level level;
  const CurrentLevelWidget({super.key, required this.level});
  @override
  Widget build(BuildContext c) => _Card('Nivel actual', Icons.stars_rounded,
      '${level.title} · Nivel ${level.number}');
}

class NextLevelWidget extends StatelessWidget {
  final Level level;
  const NextLevelWidget({super.key, required this.level});
  @override
  Widget build(BuildContext c) => _Card('Siguiente nivel',
      Icons.trending_up_rounded, '${level.currentXp}/${level.nextLevelXp} XP');
}

class MissionCard extends StatelessWidget {
  final List<Mission> missions;
  const MissionCard({super.key, required this.missions});
  @override
  Widget build(BuildContext c) => _Card(
      'Misión diaria',
      Icons.flag_rounded,
      missions.isEmpty
          ? 'Completa una sesión para activar tu próxima misión.'
          : missions
              .take(1)
              .map((m) => '${m.title}: ${m.progress}/${m.target}')
              .join('\n'));
}

class AchievementGrid extends StatelessWidget {
  final List<Achievement> achievements;
  const AchievementGrid({super.key, required this.achievements});
  @override
  Widget build(BuildContext c) {
    final pending = achievements.where((item) => !item.unlocked).toList();
    final unlocked = achievements.where((item) => item.unlocked).toList();
    final body = pending.isNotEmpty
        ? '${pending.first.title}: ${pending.first.progress}/${pending.first.target}'
        : unlocked.isNotEmpty
            ? 'Último logro: ${unlocked.first.title}'
            : 'Sigue estudiando para desbloquear tu primer logro.';
    return _Card('Logro cercano', Icons.workspace_premium_rounded, body);
  }
}

class CoinWalletWidget extends StatelessWidget {
  final CoinWallet wallet;
  const CoinWalletWidget({super.key, required this.wallet});
  @override
  Widget build(BuildContext c) => _Card('Créditos de progreso',
      Icons.monetization_on_rounded, '${wallet.balance} disponibles');
}

class CreatorProfileWidget extends StatelessWidget {
  final MarketplaceAuthor author;
  const CreatorProfileWidget({super.key, required this.author});
  @override
  Widget build(BuildContext c) => _Card(
      'Fuente del recurso',
      Icons.person_outline_rounded,
      '${author.name} · ${author.followers} seguidores');
}

class MarketplaceSuggestionsWidget extends StatelessWidget {
  final List<MarketplaceItem> items;
  const MarketplaceSuggestionsWidget({super.key, required this.items});
  @override
  Widget build(BuildContext c) => _Card(
      'Recursos sugeridos',
      Icons.storefront_rounded,
      items.isEmpty
          ? 'Sin recursos sugeridos'
          : items.take(2).map((i) => i.title).join('\n'));
}

class InstitutionHealthWidget extends StatelessWidget {
  final InstitutionMetrics metrics;
  const InstitutionHealthWidget({super.key, required this.metrics});
  @override
  Widget build(BuildContext c) => _Card(
      'Indicadores institucionales',
      Icons.health_and_safety_rounded,
      'Progreso ${metrics.progress}% · Retención ${metrics.retention}%');
}

class InstitutionAlertsWidget extends StatelessWidget {
  final List<InstitutionAlert> alerts;
  const InstitutionAlertsWidget({super.key, required this.alerts});
  @override
  Widget build(BuildContext c) => _Card(
      'Alertas institucionales',
      Icons.warning_amber_rounded,
      alerts.isEmpty
          ? 'Sin alertas institucionales'
          : alerts.take(2).map((a) => a.title).join('\n'));
}

class InstitutionKpisWidget extends StatelessWidget {
  final InstitutionMetrics metrics;
  const InstitutionKpisWidget({super.key, required this.metrics});
  @override
  Widget build(BuildContext c) => _Card(
      'Uso institucional',
      Icons.analytics_rounded,
      'IA ${metrics.aiUsage}% · Voz ${metrics.voiceUsage}% · Participación ${metrics.engagement}%');
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final String body;
  const _Card(this.title, this.icon, this.body);
  @override
  Widget build(BuildContext c) => SectionCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppTheme.accent),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w800))
        ]),
        const SizedBox(height: 10),
        Text(body,
            style: const TextStyle(color: AppTheme.textMuted, height: 1.35))
      ]));
}
