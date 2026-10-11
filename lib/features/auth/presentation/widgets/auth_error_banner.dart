import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

/// Message d'erreur d'un formulaire, annoncé aux lecteurs d'écran.
///
/// Widget autonome : fournit sa propre surface Material.
class AuthErrorBanner extends StatelessWidget {
  const new(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: colors.error,
        borderRadius: AppRadius.sm,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: colors.onError),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: colors.onError,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
