import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Écran de connexion.
///
/// PROVISOIRE (F1.7) : le formulaire de connexion arrive en F3.
/// Textes en dur migrés vers les traductions en F1.8.
class LoginPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Écran de connexion : disponible en F3',
                textAlign: TextAlign.center,
              ),
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
      ),
    );
  }
}
