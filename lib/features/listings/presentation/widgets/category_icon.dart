import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Icône d'une catégorie, d'après le nom envoyé par le serveur
/// (`/api/filters` → `categories[].icon`).
///
/// Seuls des noms connus sont acceptés : un nom inconnu (ou absent)
/// donne l'icône générique des catégories.
IconData categoryIcon(String? name) {
  return switch (name) {
    'house' => AppIcons.house,
    'shoppingBag' => AppIcons.shoppingBag,
    'wrench' => AppIcons.wrench,
    'briefcase' => AppIcons.briefcase,
    'car' => AppIcons.car,
    'magnifyingGlass' => AppIcons.magnifyingGlass,
    'megaphone' => AppIcons.megaphone,
    _ => AppIcons.squaresFour,
  };
}
