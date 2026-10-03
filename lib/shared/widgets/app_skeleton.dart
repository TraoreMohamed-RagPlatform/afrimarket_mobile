import 'package:afrimarket_mobile/core/theme/app_motion.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/listing_card.dart';
import 'package:flutter/material.dart';

/// Rectangle gris immobile : la brique de base des squelettes.
class AppSkeletonBox extends StatelessWidget {
  const new({
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.imagePlaceholder,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Fait pulser tout un groupe de squelettes avec UNE seule animation
/// (plus économe qu'une animation par rectangle).
///
/// - Immobile si l'utilisateur a demandé de réduire les animations.
/// - Annoncé une seule fois aux lecteurs d'écran (« Chargement… »).
///
/// Tests : l'animation est continue, utiliser `pump()` et jamais
/// `pumpAndSettle()`.
class AppSkeletonPulse extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<AppSkeletonPulse> createState() => _AppSkeletonPulseState();
}

class _AppSkeletonPulseState extends State<AppSkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.skeletonPulse,
    value: 1,
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.5,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.loadingLabel,
      excludeSemantics: true,
      child: FadeTransition(opacity: _opacity, child: widget.child),
    );
  }
}

/// Squelette de la grille d'annonces (premier chargement du fil, de la
/// recherche, des favoris...). Reprend exactement la forme des cartes :
/// aucun saut visuel quand les annonces arrivent.
class ListingGridSkeleton extends StatelessWidget {
  const new({this.itemCount = 6, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final textAreaHeight = ListingCard.textAreaHeight(context);

    return AppSkeletonPulse(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - AppSpacing.gridGap) / 2;

          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Wrap(
              spacing: AppSpacing.gridGap,
              runSpacing: AppSpacing.gridGap,
              children: [
                for (var i = 0; i < itemCount; i++)
                  SizedBox(
                    width: itemWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeletonBox(width: itemWidth, height: itemWidth),
                        SizedBox(
                          height: textAreaHeight,
                          child: const Padding(
                            padding: EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.md,
                            ),
                            child: FractionallySizedBox(
                              widthFactor: 0.7,
                              alignment: AlignmentDirectional.centerStart,
                              child: AppSkeletonBox(borderRadius: AppRadius.sm),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
