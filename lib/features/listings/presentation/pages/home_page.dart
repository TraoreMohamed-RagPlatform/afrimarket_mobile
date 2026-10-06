import 'dart:async';

import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/dev_tools.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page d'accueil.
///
/// PROVISOIRE : deviendra le fil d'annonces (maquette page 1) en F4.
class HomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(config.appName),
        actions: [
          IconButton(
            tooltip: l10n.logoutTooltip,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                unawaited(ref.read(sessionProvider.notifier).logout()),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.homeComingSoon),
            if (devToolsVisible(config.flavor)) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.diagnostics),
                icon: const Icon(Icons.build_outlined),
                label: Text(l10n.devDiagnosticsButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
