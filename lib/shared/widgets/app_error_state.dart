import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

/// Affiche une [Failure] avec son message traduit et un bouton
/// « Réessayer ».
///
/// - [compact] = false : plein écran (premier chargement) ;
/// - [compact] = true : une ligne en bas de liste (page suivante), pour
///   ne pas masquer les contenus déjà chargés.
///
/// Le message est annoncé automatiquement aux lecteurs d'écran.
/// Widget autonome : fournit sa propre surface Material.
class AppErrorState extends StatelessWidget {
  const new({
    required this.failure,
    this.onRetry,
    this.compact = false,
    super.key,
  });

  static const double _iconSize = 48;
  static const double _compactIconSize = 20;

  final Failure failure;
  final VoidCallback? onRetry;
  final bool compact;

  /// Icône adaptée : coupure réseau ou erreur générale.
  IconData get _icon => switch (failure) {
    NetworkFailure() || TimeoutFailure() => Icons.wifi_off_rounded,
    _ => Icons.error_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;
    final retry = onRetry;

    final message = Semantics(
      liveRegion: true,
      child: Text(
        failure.message(l10n),
        textAlign: compact ? TextAlign.start : TextAlign.center,
        style: compact ? styles.bodySmall : styles.bodyLarge,
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: compact
          ? Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    _icon,
                    size: _compactIconSize,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: message),
                  if (retry != null)
                    TextButton(onPressed: retry, child: Text(l10n.retry)),
                ],
              ),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon, size: _iconSize, color: colors.textSecondary),
                    const SizedBox(height: AppSpacing.lg),
                    message,
                    if (retry != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton.icon(
                        onPressed: retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
