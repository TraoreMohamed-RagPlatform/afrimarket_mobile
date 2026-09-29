import 'dart:async';

import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/features/health/presentation/controllers/health_controller.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page de diagnostic : vérifie la connexion au serveur (dev uniquement).
///
/// La page n'appelle jamais l'API : elle affiche l'état du contrôleur.
class HealthCheckPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final state = ref.watch(healthControllerProvider);
    final l10n = context.l10n;

    // TEMPORAIRE : couleurs remplacées par le design system en F2.
    final (icon, color, message) = switch (state) {
      HealthIdle() || HealthLoading() => (
        Icons.cloud_outlined,
        Colors.grey,
        l10n.diagnosticsIntro,
      ),
      HealthLoaded(:final status) => (
        status.isHealthy ? Icons.check_circle : Icons.error,
        status.isHealthy ? Colors.green : Colors.red,
        l10n.diagnosticsResult(
          status.status,
          status.database,
          status.websocket,
        ),
      ),
      HealthFailed(:final failure) => (
        Icons.error,
        Colors.red,
        failure.message(l10n),
      ),
    };
    final loading = state is HealthLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.diagnosticsTitle(config.appName))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${l10n.diagnosticsEnvironment(config.flavor.name)}\n'
                '${config.apiBaseUrl}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 24),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: loading
                    ? null
                    : () => unawaited(
                        ref.read(healthControllerProvider.notifier).check(),
                      ),
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(l10n.diagnosticsTestButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
