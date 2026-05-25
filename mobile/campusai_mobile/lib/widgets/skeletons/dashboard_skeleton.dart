import 'package:flutter/material.dart';

import '../../layout/responsive_layout.dart';
import '../section_card.dart';
import 'skeleton_card.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    int statsColumns = 1;

    if (ResponsiveLayout.isTablet(context)) {
      statsColumns = 2;
    }

    if (ResponsiveLayout.isDesktop(context)) {
      statsColumns = 4;
    }

    return Column(
      children: [
        /// HERO
        const SectionCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              SkeletonCard(
                height: 30,
                width: 220,
              ),
              SizedBox(height: 18),
              SkeletonCard(
                height: 16,
                width: 320,
              ),
              SizedBox(height: 12),
              SkeletonCard(
                height: 16,
                width: 260,
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        /// STATS
        GridView.count(
          crossAxisCount: statsColumns,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio:
              ResponsiveLayout.isDesktop(context)
                  ? 1.8
                  : 1.5,
          children: List.generate(
            4,
            (_) => const SectionCard(
              child: SkeletonCard(
                height: 90,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        /// TOOLS
        GridView.count(
          crossAxisCount: statsColumns,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio:
              ResponsiveLayout.isDesktop(context)
                  ? 1.15
                  : 1.1,
          children: List.generate(
            4,
            (_) => const SectionCard(
              child: SkeletonCard(
                height: 180,
              ),
            ),
          ),
        ),
      ],
    );
  }
}