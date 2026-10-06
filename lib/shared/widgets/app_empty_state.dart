import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

/// Écran vide qui INVITE à agir (« Publiez votre première annonce » +
/// bouton), plutôt qu'un simple « Aucun résultat ».
///
/// Textes et action fournis par la page.
/// Widget autonome : fournit sa propre surface Material.
class AppEmptyState extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  static const double _iconSize = 48;

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final text = message;
    final label = actionLabel;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: _iconSize, color: colors.textSecondary),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: styles.titleMedium,
                ),
              ),
              if (text != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: styles.bodySmall,
                ),
              ],
              if (label != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                FilledButton(onPressed: onAction, child: Text(label)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
