import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// En-tête des pages de navigation (fil, recherche), à placer en premier
/// dans un `CustomScrollView`.
///
/// Comportement : se masque quand on fait défiler vers le bas et réapparaît
/// dès qu'on remonte. Sa hauteur suit son contenu (grande taille de texte
/// comprise), sans calcul approximatif.
///
/// Points d'extension : [leading] (ex. ☰), [actions] (ex. 👤),
/// [search] (ex. AppSearchLauncher), [bottom] (ex. AppChipBar).
class AppSliverHeader extends StatelessWidget {
  const new({
    required this.title,
    this.leading,
    this.actions = const [],
    this.search,
    this.bottom,
    super.key,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? search;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final leadingWidget = leading;
    final searchWidget = search;
    final bottomWidget = bottom;

    return SliverFloatingHeader(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        child: ColoredBox(
          color: colors.background,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      ?leadingWidget,
                      Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: leadingWidget == null
                                ? AppSpacing.md
                                : AppSpacing.xs,
                          ),
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.displaySmall,
                            ),
                          ),
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
                if (searchWidget != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: searchWidget,
                  ),
                ?bottomWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
