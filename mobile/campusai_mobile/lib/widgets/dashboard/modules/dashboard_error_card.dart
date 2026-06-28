import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../section_card.dart';

class DashboardErrorCard extends StatelessWidget {
  final String errorMessage;

  const DashboardErrorCard({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage.isEmpty) return const SizedBox.shrink();

    return Semantics(
      container: true,
      liveRegion: true,
      child: SectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
