import 'package:flutter/material.dart';

import '../section_card.dart';

class PremiumSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const PremiumSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}
