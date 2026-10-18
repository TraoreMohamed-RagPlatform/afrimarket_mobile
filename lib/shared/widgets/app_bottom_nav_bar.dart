import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

/// Un onglet de [AppBottomNavBar].
@immutable
class AppNavItem {
  const new({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;

  /// Icône pleine de l'onglet actif : l'état ne repose jamais uniquement
  /// sur la couleur (WCAG 1.4.1).
  final IconData selectedIcon;
  final String label;

  /// Nombre d'éléments non lus (0 = pas de pastille).
  final int badgeCount;
}

/// Action centrale de [AppBottomNavBar] (ex. « Publier ») : un bouton,
/// pas un onglet.
@immutable
class AppNavAction {
  const new({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Barre de navigation du bas d'AfriMarket.
///
/// Générique : elle ne connaît ni les onglets réels, ni le routeur. La
/// coquille de l'app lui fournit [items], l'onglet actif et les actions.
///
/// - [centerAction] est placée au milieu des onglets ;
/// - pastilles de non-lus (« 99+ » au-delà de 99), lues par les
///   lecteurs d'écran (« Messages, 3 non lus ») ;
/// - onglet actif annoncé « sélectionné » ;
/// - libellés sur une seule ligne : la taille du texte est plafonnée à
///   [maxTextScale] et un libellé trop long (texte agrandi, petit écran) est
///   réduit pour tenir dans son onglet, jusqu'à [minLabelSize] ; au-delà
///   seulement, il se termine par « … » ;
/// - l'action centrale a le même poids visuel que les onglets (icône au
///   trait, couleur de la marque), comme sur Facebook Marketplace : ce sont
///   les annonces qui attirent l'œil, pas la barre.
///
/// Widget autonome : fournit sa propre surface Material.
class AppBottomNavBar extends StatelessWidget {
  const new({
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    this.centerAction,
    super.key,
  }) : assert(
         currentIndex >= 0 && currentIndex < items.length,
         'currentIndex doit désigner un onglet existant.',
       );

  /// Hauteur minimale de chaque zone tactile.
  static const double minTouchHeight = 48;

  /// Agrandissement maximal du texte dans la barre. Au-delà, cinq libellés
  /// ne tiennent plus côte à côte sur un téléphone ; le reste de l'app suit
  /// le réglage du système sans limite.
  static const double maxTextScale = 1.5;

  /// Taille réelle minimale d'un libellé : plus petit, il ne serait plus
  /// lisible (et son contraste plus mesurable de façon fiable).
  static const double minLabelSize = 11;

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final AppNavAction? centerAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final action = centerAction;

    final tabs = <Widget>[
      for (var i = 0; i < items.length; i++)
        _NavTab(
          item: items[i],
          selected: i == currentIndex,
          onTap: () => onSelect(i),
        ),
    ];
    if (action != null) {
      tabs.insert(items.length ~/ 2, _NavActionButton(action: action));
    }

    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: maxTextScale,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [for (final tab in tabs) Expanded(child: tab)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const new({required this.item, required this.selected, required this.onTap});

  static const int _maxShownCount = 99;

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final count = item.badgeCount;
    final color = selected ? colors.brand : colors.textSecondary;
    final semanticLabel = count > 0
        ? '${item.label}, ${l10n.unreadCount(count)}'
        : item.label;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppBottomNavBar.minTouchHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Badge(
                isLabelVisible: count > 0,
                backgroundColor: colors.error,
                textColor: colors.onError,
                label: Text(
                  count > _maxShownCount ? '$_maxShownCount+' : '$count',
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              _NavLabel(
                item.label,
                style: context.textStyles.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavActionButton extends StatelessWidget {
  const new({required this.action});

  final AppNavAction action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: action.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppBottomNavBar.minTouchHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(action.icon, color: colors.brand),
              const SizedBox(height: 2),
              _NavLabel(
                action.label,
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Libellé d'onglet sur une ligne, réduit pour tenir plutôt que coupé.
///
/// La taille de police elle-même est diminuée (pas de mise à l'échelle
/// graphique) : le texte reste net et les contrôles d'accessibilité
/// mesurent le contraste là où il est réellement dessiné.
class _NavLabel extends StatelessWidget {
  const new(this.text, {required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth;
          // Taille de police (avant agrandissement du système) qui donne
          // [AppBottomNavBar.minLabelSize] à l'écran.
          final minFontSize =
              AppBottomNavBar.minLabelSize / textScaler.scale(1);
          var fitted = base;
          // L'espacement des lettres ne suit pas la taille de police : on
          // réduit les deux ensemble et on vérifie la mesure (2 passes au
          // plus suffisent).
          for (var pass = 0; pass < 3 && available.isFinite; pass++) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: fitted),
              textDirection: textDirection,
              textScaler: textScaler,
              maxLines: 1,
            )..layout();
            final width = painter.width;
            painter.dispose();

            final fontSize = fitted.fontSize;
            if (fontSize == null ||
                width <= available ||
                fontSize <= minFontSize) {
              break;
            }
            final target = fontSize * available / width * 0.98;
            final factor =
                (target < minFontSize ? minFontSize : target) / fontSize;
            fitted = fitted.copyWith(
              fontSize: fontSize * factor,
              letterSpacing: (fitted.letterSpacing ?? 0) * factor,
            );
          }
          return Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: fitted,
          );
        },
      ),
    );
  }
}
