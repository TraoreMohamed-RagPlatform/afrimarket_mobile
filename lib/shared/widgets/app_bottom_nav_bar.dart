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
/// - onglet actif annoncé « sélectionné ».
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [for (final tab in tabs) Expanded(child: tab)],
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
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  static const double _circleSize = 32;
  static const double _iconSize = 20;

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
              Container(
                width: _circleSize,
                height: _circleSize,
                decoration: BoxDecoration(
                  color: colors.brand,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action.icon,
                  size: _iconSize,
                  color: colors.onBrand,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
