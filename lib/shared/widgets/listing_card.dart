import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/formatters/price_formatter.dart';
import 'package:afrimarket_mobile/shared/formatters/user_text.dart';
import 'package:afrimarket_mobile/shared/widgets/app_badge.dart';
import 'package:afrimarket_mobile/shared/widgets/app_network_image.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card_status.dart';
import 'package:flutter/material.dart';

/// Carte d'annonce de la grille (style Marketplace) :
/// photo carrée bord à bord, badges, puis « prix · titre ».
///
/// Widget partagé et autonome : il ne dépend d'aucune fonctionnalité et
/// fournit sa propre surface Material (fonctionne avec ou sans Scaffold).
///
/// Points d'extension :
/// - [badges] : nouveaux badges sans modifier la carte ;
/// - [action] : emplacement en haut, côté fin (ex. bouton « Enregistrer »
///   de la fonctionnalité Favoris). Le toucher de l'action n'ouvre pas
///   l'annonce ; l'action doit offrir une zone tactile de 48 × 48 et son
///   propre libellé pour les lecteurs d'écran ;
/// - [status] : disponible, réservé ou vendu.
///
/// Mise en page : la carte mesure elle-même la hauteur de sa zone de texte
/// ([textAreaHeight]) ; les grilles l'utilisent pour dimensionner les
/// cellules, sans calcul approximatif.
class ListingCard extends StatelessWidget {
  const new({
    required this.title,
    required this.price,
    required this.onTap,
    this.imageUrl,
    this.oldPrice,
    this.badges = const [],
    this.status = ListingCardStatus.available,
    this.action,
    super.key,
  });

  /// Marge verticale totale autour du texte.
  static const double textPadding = AppSpacing.sm * 2;

  /// Nombre maximal de badges affichés, pour ne pas masquer la photo.
  static const int maxVisibleBadges = 2;

  /// Largeur réservée à l'action, pour que les badges ne passent pas dessous.
  static const double _actionReservedWidth = 48;

  /// Matrice de conversion en noir et blanc (luminance ITU-R BT.709).
  static const _greyscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  final String title;
  final num price;
  final num? oldPrice;
  final String? imageUrl;
  final List<AppBadgeType> badges;
  final ListingCardStatus status;
  final Widget? action;
  final VoidCallback onTap;

  /// Style de base de la zone de texte.
  static TextStyle _textStyle(BuildContext context) =>
      context.textStyles.bodyMedium ?? const TextStyle();

  /// Hauteur de ligne imposée, identique quelle que soit la police
  /// (latin, arabe, gras) : garantit une hauteur prévisible.
  static StrutStyle _strut(TextStyle style) =>
      StrutStyle.fromTextStyle(style, forceStrutHeight: true);

  /// Hauteur exacte de la zone de texte sous la photo, mesurée avec le
  /// moteur de mise en page, en tenant compte de la taille de texte
  /// choisie sur le téléphone.
  static double textAreaHeight(BuildContext context) {
    final style = _textStyle(context);
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: style),
      strutStyle: _strut(style),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height.ceilToDouble() + textPadding;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final baseStyle = _textStyle(context);

    final isSold = status == ListingCardStatus.sold;
    final formattedPrice = formatPrice(price, l10n);
    final previous = oldPrice;
    final showOldPrice = previous != null && previous > price;
    final actionWidget = action;

    // Le statut « Réservé » est affiché comme un badge, en premier.
    final visibleBadges = <AppBadgeType>[
      if (status == ListingCardStatus.reserved) AppBadgeType.reserved,
      ...badges,
    ].take(maxVisibleBadges).toList();

    final statusLabel = switch (status) {
      ListingCardStatus.available => null,
      ListingCardStatus.reserved => l10n.listingStatusReserved,
      ListingCardStatus.sold => l10n.listingStatusSold,
    };
    final semanticLabel = [
      ?statusLabel,
      formattedPrice,
      stripBidiControls(title),
    ].join(', ');

    Widget image = AppNetworkImage(url: imageUrl);
    if (isSold) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_greyscale),
        child: image,
      );
    }

    return Stack(
      children: [
        // Carte : un seul élément pour les lecteurs d'écran.
        Semantics(
          button: true,
          label: semanticLabel,
          excludeSemantics: true,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        image,
                        if (isSold) ...[
                          ColoredBox(
                            color: colors.background.withValues(alpha: 0.4),
                          ),
                          Center(child: _SoldLabel(l10n.listingStatusSold)),
                        ],
                        if (visibleBadges.isNotEmpty)
                          PositionedDirectional(
                            top: AppSpacing.sm,
                            start: AppSpacing.sm,
                            end: actionWidget == null
                                ? AppSpacing.sm
                                : AppSpacing.sm + _actionReservedWidth,
                            child: Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                for (final badge in visibleBadges)
                                  AppBadge(badge),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: baseStyle.copyWith(
                          color: isSold ? colors.textSecondary : null,
                        ),
                        children: [
                          TextSpan(
                            text: formattedPrice,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (showOldPrice)
                            TextSpan(
                              text: ' ${formatPrice(previous, l10n)}',
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: colors.textSecondary,
                              ),
                            ),
                          TextSpan(text: ' · ${userText(title)}'),
                        ],
                      ),
                      strutStyle: _strut(baseStyle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Zone tactile par-dessus toute la carte (photo comprise).
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap),
                ),
              ),
            ],
          ),
        ),
        // Action : au-dessus de la zone tactile, annoncée séparément.
        if (actionWidget != null)
          PositionedDirectional(
            top: AppSpacing.xs,
            end: AppSpacing.xs,
            child: Material(
              type: MaterialType.transparency,
              child: actionWidget,
            ),
          ),
      ],
    );
  }
}

/// Mention « Vendu » au centre de la photo.
class _SoldLabel extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.textPrimary,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.labelLarge?.copyWith(
          color: colors.background,
        ),
      ),
    );
  }
}
