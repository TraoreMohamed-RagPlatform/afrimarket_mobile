import 'dart:async';

import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Page d'accueil.
///
/// PROVISOIRE (F1.7) : deviendra le fil d'annonces (maquette page 1) en F4.
/// Textes en dur migrés vers les traductions en F1.8.
class HomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(config.appName),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
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
            const Text('Accueil : le fil d’annonces arrive en F4'),
            if (config.flavor == Flavor.dev) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.diagnostics),
                icon: const Icon(Icons.build_outlined),
                label: const Text('Diagnostic (dev)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
