import 'dart:async';

import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/features/inbox/presentation/unread_counts_controller.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:afrimarket_mobile/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Coquille de l'app : les onglets et la barre du bas (ADR 0003).
///
/// Chaque onglet garde sa propre navigation et sa position de
/// défilement. Toucher l'onglet actif ramène à sa première page.
///
/// Pastilles : messages et notifications non lus (connecté seulement),
/// relues toutes les [unreadRefreshInterval], au retour dans l'app et à
/// chaque changement d'onglet. Le minuteur vit avec la barre du bas : il
/// s'arrête dès qu'elle disparaît.
///
/// L'ordre des onglets DOIT correspondre à l'ordre des branches déclarées
/// dans le routeur (app_router.dart).
class AppShell extends ConsumerStatefulWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Rythme d'actualisation des pastilles : léger pour la batterie et le
  /// serveur.
  static const unreadRefreshInterval = Duration(minutes: 1);

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final Timer _timer;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(AppShell.unreadRefreshInterval, (_) => _refresh());
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _timer.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _refresh() =>
      unawaited(ref.read(unreadCountsProvider.notifier).refresh());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navigationShell = widget.navigationShell;
    final current = navigationShell.currentIndex;
    final unread = ref.watch(unreadCountsProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: current,
        onSelect: (index) {
          navigationShell.goBranch(index, initialLocation: index == current);
          _refresh();
        },
        items: [
          AppNavItem(
            icon: AppIcons.house,
            selectedIcon: AppIconsFill.house,
            label: l10n.navHome,
          ),
          AppNavItem(
            icon: AppIcons.bell,
            selectedIcon: AppIconsFill.bell,
            label: l10n.navNotifications,
            badgeCount: unread.notifications,
          ),
          AppNavItem(
            icon: AppIcons.chatCircle,
            selectedIcon: AppIconsFill.chatCircle,
            label: l10n.navMessages,
            badgeCount: unread.messages,
          ),
          AppNavItem(
            icon: AppIcons.star,
            selectedIcon: AppIconsFill.star,
            label: l10n.navFavorites,
          ),
        ],
        centerAction: AppNavAction(
          icon: AppIcons.plusCircle,
          label: l10n.navPublish,
          onTap: () => unawaited(context.push(AppRoutes.publish)),
        ),
      ),
    );
  }
}
