import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

/// Photos d'une annonce : carré bord à bord, balayage horizontal,
/// compteur « 1 / 4 », et boutons posés sur la photo (retour, partager...).
///
/// Sans photo : le fond neutre de [AppNetworkImage].
class ListingPhotoGallery extends StatefulWidget {
  const new({
    required this.imageUrls,
    this.leading,
    this.actions = const [],
    this.greyscale = false,
    super.key,
  });

  final List<String> imageUrls;

  /// Bouton en haut, côté début (retour).
  final Widget? leading;

  /// Boutons en haut, côté fin (partager, plus d'options).
  final List<Widget> actions;

  /// Photos en noir et blanc (article vendu).
  final bool greyscale;

  @override
  State<ListingPhotoGallery> createState() => _ListingPhotoGalleryState();
}

class _ListingPhotoGalleryState extends State<ListingPhotoGallery> {
  /// Conversion en noir et blanc (luminance ITU-R BT.709).
  static const _greyscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final urls = widget.imageUrls;
    final total = urls.length;
    final leading = widget.leading;

    var photos = total == 0
        ? const AppNetworkImage(url: null)
        : PageView.builder(
            itemCount: total,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => AppNetworkImage(
              url: urls[index],
              semanticLabel: l10n.listingPhotoLabel(index + 1, total),
            ),
          );
    if (widget.greyscale) {
      photos = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_greyscale),
        child: photos,
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          photos,
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    ?leading,
                    const Spacer(),
                    for (final action in widget.actions) ...[
                      const SizedBox(width: AppSpacing.sm),
                      action,
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (total > 1)
            PositionedDirectional(
              end: AppSpacing.md,
              bottom: AppSpacing.md,
              child: ExcludeSemantics(
                child: _OverlayPill(
                  child: Text(
                    l10n.listingPhotoCounter(_index + 1, total),
                    style: context.textStyles.labelSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bouton rond posé sur une photo (retour, partager, plus d'options).
///
/// Fond clair presque opaque : lisible sur n'importe quelle photo, en
/// clair comme en sombre (contraste garanti par les couleurs du thème).
class ListingPhotoButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: colors.textPrimary,
      style: IconButton.styleFrom(
        backgroundColor: colors.surface.withValues(alpha: 0.92),
        minimumSize: const Size.square(48),
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.92),
        borderRadius: AppRadius.pill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        child: child,
      ),
    );
  }
}
