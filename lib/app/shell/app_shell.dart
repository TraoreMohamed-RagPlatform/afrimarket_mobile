import 'dart:async';

import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Coquille de l'app : les onglets et la barre du bas (ADR 0003).
///
/// Chaque onglet garde sa propre navigation et sa position de
/// défilement. Toucher l'onglet actif ramène à sa première page.
///
/// L'ordre des onglets DOIT correspondre à l'ordre des branches déclarées
/// dans le routeur (app_router.dart).
class AppShell extends StatelessWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: current,
        onSelect: (index) =>
            navigationShell.goBranch(index, initialLocation: index == current),
        // Les compteurs de non-lus seront branchés avec la messagerie et
        // les notifications.
        items: [
          AppNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: l10n.navHome,
          ),
          AppNavItem(
            icon: Icons.star_border,
            selectedIcon: Icons.star,
            label: l10n.navFavorites,
          ),
          AppNavItem(
            icon: Icons.chat_bubble_outline,
            selectedIcon: Icons.chat_bubble,
            label: l10n.navMessages,
          ),
          AppNavItem(
            icon: Icons.notifications_none,
            selectedIcon: Icons.notifications,
            label: l10n.navNotifications,
          ),
        ],
        centerAction: AppNavAction(
          icon: Icons.add,
          label: l10n.navPublish,
          onTap: () => unawaited(context.push(AppRoutes.publish)),
        ),
      ),
    );
  }
}
