import 'package:flutter/material.dart';

/// Bouton principal d'un formulaire d'authentification.
///
/// Pendant l'envoi, il est désactivé et affiche un indicateur ; le
/// libellé reste annoncé aux lecteurs d'écran.
class AuthSubmitButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  /// Hauteur minimale (zone tactile confortable).
  static const double minHeight = 48;
  static const double _indicatorSize = 20;

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(minHeight),
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? Semantics(
              label: label,
              child: const SizedBox.square(
                dimension: _indicatorSize,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Text(label),
    );
  }
}
