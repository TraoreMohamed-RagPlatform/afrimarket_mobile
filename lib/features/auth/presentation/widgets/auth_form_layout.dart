import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Mise en page commune des écrans d'authentification.
///
/// - Contenu défilant : rien n'est masqué par le clavier ni par une grande
///   taille de texte ;
/// - largeur limitée sur tablette, pour garder des lignes lisibles.
class AuthFormLayout extends StatelessWidget {
  const new({required this.title, required this.child, super.key});

  /// Largeur maximale du formulaire.
  static const double maxWidth = 480;

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.page),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
