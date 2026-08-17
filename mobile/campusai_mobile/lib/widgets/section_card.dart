import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionCard extends StatefulWidget {
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
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  bool isHovered = false;
  bool isPressed = false;

  bool get isClickable => widget.onTap != null;

  void setHover(bool value) {
    if (!mounted) return;

    setState(() {
      isHovered = value;

      if (!value) {
        isPressed = false;
      }
    });
  }

  void setPressed(bool value) {
    if (!mounted || !isClickable) return;

    setState(() {
      isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = isPressed ? 0.985 : (isHovered ? 1.008 : 1.0);

    final borderColor = isHovered
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.05);

    final card = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: widget.padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.card,
              AppTheme.cardSoft.withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isHovered ? 0.24 : 0.18,
              ),
              blurRadius: isHovered ? 28 : 18,
              offset: Offset(0, isHovered ? 16 : 12),
            ),
            BoxShadow(
              color: AppTheme.primary.withValues(
                alpha: isHovered ? 0.10 : 0.03,
              ),
              blurRadius: isHovered ? 26 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.child,
      ),
    );

    Widget content = MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setHover(true),
      onExit: (_) => setHover(false),
      child: card,
    );

    if (!isClickable) {
      return content;
    }

    return GestureDetector(
      onTapDown: (_) => setPressed(true),
      onTapUp: (_) => setPressed(false),
      onTapCancel: () => setPressed(false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(26),
          splashColor: AppTheme.primary.withValues(alpha: 0.10),
          highlightColor: Colors.transparent,
          child: content,
        ),
      ),
    );
  }
}
