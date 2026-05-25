import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isDisabled ? 0.55 : 1,
      child: AnimatedScale(
        scale: isPressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: isDisabled
                ? null
                : (_) {
                    setState(() {
                      isPressed = true;
                    });
                  },
            onTapUp: isDisabled
                ? null
                : (_) {
                    setState(() {
                      isPressed = false;
                    });
                  },
            onTapCancel: isDisabled
                ? null
                : () {
                    setState(() {
                      isPressed = false;
                    });
                  },
            borderRadius: BorderRadius.circular(28),
            splashColor: AppTheme.primary.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            child: Ink(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.card,
                    AppTheme.cardSoft.withValues(alpha: 0.96),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: AppTheme.mainGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    isDisabled
                        ? Icons.lock_outline_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}