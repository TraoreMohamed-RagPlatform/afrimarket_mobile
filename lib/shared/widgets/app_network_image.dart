import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Photo chargée depuis le réseau, mise en cache sur l'appareil.
///
/// - fond neutre pendant le chargement, icône en cas d'erreur ;
/// - image décodée à la taille affichée (économie de mémoire) ;
/// - sécurité : seules les adresses http(s) sont acceptées. Toute autre
///   adresse (file://, javascript:...) affiche simplement le fond neutre.
class AppNetworkImage extends StatelessWidget {
  const new({
    required this.url,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    super.key,
  });

  final String? url;
  final BoxFit fit;
  final String? semanticLabel;

  /// Vrai si [url] est une adresse web autorisée.
  static bool isAllowedUrl(String? url) {
    final uri = Uri.tryParse(url ?? '');
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null || !isAllowedUrl(imageUrl)) {
      return const _Placeholder(icon: Icons.image_outlined);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final pixelRatio = MediaQuery.devicePixelRatioOf(context);
        final width = constraints.maxWidth;
        final cacheWidth = width.isFinite ? (width * pixelRatio).round() : null;

        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          memCacheWidth: cacheWidth,
          imageBuilder: (context, provider) =>
              Image(image: provider, fit: fit, semanticLabel: semanticLabel),
          placeholder: (context, _) => const _Placeholder(),
          errorWidget: (context, _, _) =>
              const _Placeholder(icon: Icons.broken_image_outlined),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const new({this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final placeholderIcon = icon;

    return ColoredBox(
      color: colors.imagePlaceholder,
      child: placeholderIcon == null
          ? const SizedBox.expand()
          : Center(child: Icon(placeholderIcon, color: colors.textSecondary)),
    );
  }
}
