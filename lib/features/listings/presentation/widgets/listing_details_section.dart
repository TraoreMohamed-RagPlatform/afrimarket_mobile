import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_section_header.dart';
import 'package:flutter/material.dart';

/// Section « Détails » : état, catégorie, remise, puis la description
/// (repliée au-delà de quelques lignes, avec « Voir plus »).
class ListingDetailsSection extends StatelessWidget {
  const new({required this.listing, super.key});

  final ListingDetail listing;

  static String conditionLabel(
    ListingCondition condition,
    AppLocalizations l10n,
  ) {
    return switch (condition) {
      ListingCondition.brandNew => l10n.conditionNew,
      ListingCondition.likeNew => l10n.conditionLikeNew,
      ListingCondition.good => l10n.conditionGood,
      ListingCondition.fair => l10n.conditionFair,
      ListingCondition.poor => l10n.conditionPoor,
    };
  }

  static String deliveryLabel(DeliveryMode mode, AppLocalizations l10n) {
    return switch (mode) {
      DeliveryMode.pickup => l10n.deliveryPickup,
      DeliveryMode.delivery => l10n.deliveryDelivery,
      DeliveryMode.both => l10n.deliveryBoth,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final condition = listing.condition;
    final category = listing.categoryName;

    final rows = [
      if (condition != null)
        (l10n.listingConditionLabel, conditionLabel(condition, l10n)),
      if (category != null) (l10n.listingCategoryLabel, userText(category)),
      (l10n.listingDeliveryLabel, deliveryLabel(listing.deliveryMode, l10n)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.listingDetailsTitle),
        for (final (label, value) in rows)
          _DetailRow(label: label, value: value),
        if (listing.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _ExpandableText(userText(listing.description)),
        ],
      ],
    );
  }
}

/// « Libellé    valeur », sur deux colonnes ; le libellé passe au-dessus
/// de la valeur quand la place manque (texte agrandi).
class _DetailRow extends StatelessWidget {
  const new({required this.label, required this.value});

  static const double _labelWidth = 112;

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: MergeSemantics(
        child: Wrap(
          spacing: AppSpacing.md,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: _labelWidth),
              child: Text(label, style: styles.bodySmall),
            ),
            Text(value, style: styles.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Texte replié à [maxLines] lignes, avec « Voir plus » / « Voir moins »
/// seulement s'il dépasse vraiment.
class _ExpandableText extends StatefulWidget {
  const new(this.text);

  static const maxLines = 6;

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = context.textStyles.bodyLarge;

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _ExpandableText.maxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : _ExpandableText.maxLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (overflows)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 48),
                ),
                child: Text(
                  _expanded ? l10n.listingSeeLess : l10n.listingSeeMore,
                ),
              ),
          ],
        );
      },
    );
  }
}
