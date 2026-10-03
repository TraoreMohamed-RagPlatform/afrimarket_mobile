import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Messages de confirmation d'AfriMarket.
///
/// - [showAppSnackBar] : message simple, action facultative ;
/// - [showUndoSnackBar] : message avec « Annuler » (ex. « Annonce
///   enregistrée · Annuler »).
///
/// Un nouveau message remplace le précédent, pour ne pas les empiler.
extension AppSnackBarContext on BuildContext {
  void showAppSnackBar(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
        ),
      );
  }

  void showUndoSnackBar(String message, {required VoidCallback onUndo}) {
    showAppSnackBar(message, actionLabel: l10n.undo, onAction: onUndo);
  }
}
