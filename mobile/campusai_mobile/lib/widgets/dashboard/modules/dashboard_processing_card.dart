import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../section_card.dart';

class DashboardProcessingCard extends StatelessWidget {
  const DashboardProcessingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Procesando documento...',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Generando resumen IA, audio y embeddings RAG.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.45,
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