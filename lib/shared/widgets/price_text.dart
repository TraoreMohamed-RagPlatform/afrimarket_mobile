import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/price_formatter.dart';
import 'package:flutter/material.dart';

/// Prix d'une annonce, avec l'ancien prix barré en cas de baisse.
///
/// L'ancien prix n'est affiché que s'il est supérieur au prix actuel.
class PriceText extends StatelessWidget {
  const new({required this.price, this.oldPrice, this.style, super.key});

  final num price;
  final num? oldPrice;

  /// Style du prix (par défaut : titleMedium, en gras).
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final priceStyle = style ?? context.textStyles.titleMedium;
    final previous = oldPrice;
    final showOldPrice = previous != null && previous > price;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: formatPrice(price, l10n), style: priceStyle),
          if (showOldPrice) ...[
            const TextSpan(text: '  '),
            TextSpan(
              text: formatPrice(previous, l10n),
              style: context.textStyles.bodySmall?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
