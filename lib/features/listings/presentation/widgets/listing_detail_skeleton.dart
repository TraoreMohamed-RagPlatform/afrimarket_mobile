import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';

/// Squelette de la page de détail : photo carrée, titre, prix, lieu,
/// bloc de message. Même forme que la page : aucun saut à l'arrivée.
class ListingDetailSkeleton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeletonPulse(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AspectRatio(aspectRatio: 1, child: AppSkeletonBox()),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (width, height) in const [
                    (0.8, 24.0),
                    (0.4, 20.0),
                    (0.6, 14.0),
                  ]) ...[
                    FractionallySizedBox(
                      widthFactor: width,
                      child: AppSkeletonBox(
                        height: height,
                        borderRadius: AppRadius.sm,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  const AppSkeletonBox(height: 96, borderRadius: AppRadius.sm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
