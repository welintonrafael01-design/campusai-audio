import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'premium_section_card.dart';

class StudyBookBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StudyBookBadge({
    super.key,
    required this.label,
    this.color = AppTheme.accent,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class StudyBookChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const StudyBookChip({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: icon == null ? null : Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class StudyBookMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StudyBookMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumSectionCard(
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
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
