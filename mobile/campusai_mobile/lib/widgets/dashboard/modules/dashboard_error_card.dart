import 'package:flutter/material.dart';

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

    return SectionCard(
      child: Text(
        errorMessage,
        style: const TextStyle(
          color: Colors.redAccent,
          height: 1.5,
        ),
      ),
    );
  }
}
