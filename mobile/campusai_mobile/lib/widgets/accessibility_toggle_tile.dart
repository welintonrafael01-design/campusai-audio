import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AccessibilityToggleTile extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  const AccessibilityToggleTile({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      toggled: value,
      label: title,
      hint: description,
      child: ExcludeSemantics(
        child: SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          secondary: Icon(icon, color: AppTheme.accent),
          title: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            description,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
