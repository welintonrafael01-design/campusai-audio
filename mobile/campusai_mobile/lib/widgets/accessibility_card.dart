import 'package:flutter/material.dart';

import '../services/accessibility/accessibility_models.dart';
import '../theme/app_theme.dart';
import 'studybook/premium_section_card.dart';
import 'studybook/studybook_buttons.dart';

class AccessibilityCard extends StatelessWidget {
  final AccessibilityPreferences preferences;
  final VoidCallback onAdjust;

  const AccessibilityCard({
    super.key,
    required this.preferences,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Aprende a tu manera. Preferencias de accesibilidad.',
      child: PremiumSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.accessibility_new_rounded, color: AppTheme.accent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aprende a tu manera',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Puedes escuchar, leer, repasar paso a paso o pedir una explicación simple. Booky adapta la experiencia para que estudies con más comodidad.',
              style: TextStyle(color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _PreferenceStatus(
                  label: 'Preferir audio',
                  enabled: preferences.preferAudio,
                  icon: Icons.headphones_rounded,
                ),
                _PreferenceStatus(
                  label: 'Texto grande',
                  enabled: preferences.largeText,
                  icon: Icons.text_increase_rounded,
                ),
                _PreferenceStatus(
                  label: 'Lenguaje simple',
                  enabled: preferences.simpleLanguage,
                  icon: Icons.short_text_rounded,
                ),
                _PreferenceStatus(
                  label: 'Alto contraste',
                  enabled: preferences.highContrast,
                  icon: Icons.contrast_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            StudyBookSecondaryButton(
              label: 'Ajustar preferencias',
              icon: Icons.tune_rounded,
              onPressed: onAdjust,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceStatus extends StatelessWidget {
  final String label;
  final bool enabled;
  final IconData icon;

  const _PreferenceStatus({
    required this.label,
    required this.enabled,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final stateLabel = enabled ? 'Activado' : 'Estándar';
    final color = enabled ? AppTheme.success : AppTheme.textMuted;
    return Semantics(
      label: '$label, $stateLabel',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 7),
              Text(
                '$label · $stateLabel',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
