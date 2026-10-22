import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:flutter/material.dart';

/// État d'envoi d'une bulle.
enum BubbleDelivery {
  /// Confirmé par le serveur.
  sent,

  /// En cours d'envoi.
  sending,

  /// Non envoyé.
  failed,
}

/// Une bulle de message (maquette page 9) : les miens à droite en terre
/// cuite, ceux de l'autre à gauche en gris. Arrondi de 8, coin pointu du
/// côté de l'expéditeur.
class ChatBubble extends StatelessWidget {
  const new({
    required this.text,
    required this.isMine,
    this.meta,
    this.delivery = BubbleDelivery.sent,
    this.onRetry,
    this.onDiscard,
    super.key,
  });

  /// Largeur maximale, en part de la largeur disponible.
  static const double maxWidthFactor = 0.78;

  final String text;
  final bool isMine;

  /// Ligne sous la bulle (« 10:42 · Vu », « Envoi… »...), si elle existe.
  final String? meta;

  final BubbleDelivery delivery;

  /// Message non envoyé : nouvel essai, retrait.
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    const tail = Radius.circular(2);
    const round = Radius.circular(8);
    final radius = BorderRadiusDirectional.only(
      topStart: round,
      topEnd: round,
      bottomStart: isMine ? round : tail,
      bottomEnd: isMine ? tail : round,
    );
    final failed = delivery == BubbleDelivery.failed;
    final caption = meta;

    final bubble = LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: constraints.maxWidth * maxWidthFactor,
        ),
        child: Opacity(
          opacity: delivery == BubbleDelivery.sending ? 0.6 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isMine ? colors.brand : colors.surfaceMuted,
              borderRadius: radius,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                userText(text),
                style: styles.bodyLarge?.copyWith(
                  color: isMine ? colors.onBrand : colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMine
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: bubble,
        ),
        if (failed)
          _FailedLine(onRetry: onRetry, onDiscard: onDiscard, label: caption)
        else if (caption != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
            child: Text(
              caption,
              style: styles.labelSmall?.copyWith(color: colors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _FailedLine extends StatelessWidget {
  const new({required this.onRetry, required this.onDiscard, this.label});

  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: TextButton.icon(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: colors.error),
            icon: const Icon(AppIcons.warningCircle, size: 18),
            label: Text(
              label ?? '',
              style: styles.labelSmall?.copyWith(color: colors.error),
            ),
          ),
        ),
        if (onDiscard != null)
          IconButton(
            onPressed: onDiscard,
            tooltip: context.l10n.chatDiscard,
            icon: Icon(AppIcons.trash, size: 18, color: colors.textSecondary),
          ),
      ],
    );
  }
}
