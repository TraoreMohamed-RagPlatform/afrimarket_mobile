import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_logo.dart';
import 'package:afrimarket_mobile/shared/widgets/bogolan_strip.dart';
import 'package:flutter/material.dart';

/// Mise en page commune des écrans d'authentification.
///
/// - En-tête de marque : le motif bogolan, puis le logo (charte : l'un des
///   trois seuls endroits où le motif apparaît) ;
/// - Contenu défilant : rien n'est masqué par le clavier ni par une grande
///   taille de texte ;
/// - largeur limitée sur tablette, pour garder des lignes lisibles.
class AuthFormLayout extends StatelessWidget {
  const new({required this.title, required this.child, super.key});

  /// Largeur maximale du formulaire.
  static const double maxWidth = 480;

  /// Hauteur du symbole du logo dans l'en-tête.
  static const double logoHeight = 40;

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Column(
          children: [
            BogolanStrip(
              color: context.colors.brand.withValues(alpha: 0.35),
              height: AppSpacing.xxl,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AppLogo(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
