import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      side: BorderSide(
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );

    return Semantics(
      button: onTap != null,
      child: Material(
        color: AppTheme.card,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: colors.primary.withValues(alpha: 0.10),
          highlightColor: colors.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppTheme.space20),
            child: child,
          ),
        ),
      ),
    );
  }
}
