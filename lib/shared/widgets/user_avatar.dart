import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';

/// Tailles d'avatar.
enum AvatarSize {
  small(32),
  medium(48),
  large(80);

  new(this.diameter);

  final double diameter;
}

/// Photo ronde d'un utilisateur, avec ses initiales si la photo est absente
/// (ou refusée), et le badge ✓ si son identité est vérifiée.
class UserAvatar extends StatelessWidget {
  const new({
    required this.name,
    this.imageUrl,
    this.size = AvatarSize.medium,
    this.verified = false,
    super.key,
  });

  final String name;
  final String? imageUrl;
  final AvatarSize size;
  final bool verified;

  /// Initiales (2 au maximum), compatibles avec l'arabe.
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final diameter = size.diameter;
    final badgeSize = diameter * 0.42;
    final url = imageUrl;
    final hasPhoto = AppNetworkImage.isAllowedUrl(url);

    return Semantics(
      image: true,
      label: verified ? context.l10n.avatarVerified(name) : name,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: diameter,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: SizedBox.square(
                dimension: diameter,
                child: hasPhoto
                    ? AppNetworkImage(url: url)
                    : ColoredBox(
                        color: colors.brandSoft,
                        child: Center(
                          child: Text(
                            initialsOf(name),
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: colors.onBrandSoft,
                              fontSize: diameter * 0.38,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            if (verified)
              PositionedDirectional(
                end: -2,
                bottom: -2,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: colors.brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.background, width: 2),
                  ),
                  child: Icon(
                    Icons.check,
                    size: badgeSize * 0.62,
                    color: colors.onBrand,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
