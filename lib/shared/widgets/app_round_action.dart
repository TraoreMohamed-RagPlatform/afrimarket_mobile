import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

/// Bouton d'action rond avec libellé dessous (Message, Partager,
/// Enregistrer...).
///
/// Point d'extension : état [active] (ex. annonce enregistrée), avec une
/// icône et un libellé propres ; il est annoncé aux lecteurs d'écran
/// comme un interrupteur (activé / désactivé).
///
/// Widget autonome : fournit sa propre surface Material.
class AppRoundAction extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeIcon,
    this.activeLabel,
    super.key,
  });

  /// Diamètre du cercle (zone tactile minimale Material).
  static const double circleSize = 48;

  /// Largeur minimale de la zone tactile (cercle + libellé).
  static const double minWidth = 64;

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Vrai si l'action est active (ex. annonce déjà enregistrée).
  final bool active;
  final IconData? activeIcon;
  final String? activeLabel;

  /// Vrai si l'action fonctionne comme un interrupteur.
  bool get _isToggle => activeIcon != null || activeLabel != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shownLabel = active ? (activeLabel ?? label) : label;
    final shownIcon = active ? (activeIcon ?? icon) : icon;

    return Semantics(
      button: true,
      toggled: _isToggle ? active : null,
      label: shownLabel,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.md,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: minWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: active ? colors.brandSoft : colors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      shownIcon,
                      color: active ? colors.onBrandSoft : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    shownLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: active ? colors.brand : colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
