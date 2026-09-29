import 'dart:async';
import 'dart:convert';

import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Page de diagnostic : vérifie la connexion au backend (dev uniquement).
///
/// TEMPORAIRE : l'appel API est fait directement depuis l'écran.
/// Il sera migré en F1.9 vers les couches data/domain, avec Dio.
class HealthCheckPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<HealthCheckPage> createState() => _HealthCheckPageState();
}

class _HealthCheckPageState extends ConsumerState<HealthCheckPage> {
  bool _loading = false;
  bool? _success;
  String? _message;

  Future<void> _checkBackend() async {
    final config = ref.read(appConfigProvider);
    final l10n = context.l10n;
    setState(() => _loading = true);

    try {
      final response = await http
          .get(config.apiBaseUrl.resolve('/api/health'))
          .timeout(const Duration(seconds: 5));
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _success = response.statusCode == 200 && data['status'] == 'ok';
        _message = l10n.diagnosticsResult(
          '${data['status']}',
          '${data['database']}',
          '${data['websocket']}',
        );
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _success = false;
        _message = l10n.diagnosticsTimeout;
      });
    } on Exception {
      // Aucun détail technique n'est affiché (sécurité).
      if (!mounted) return;
      setState(() {
        _success = false;
        _message = l10n.diagnosticsError;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final l10n = context.l10n;
    final success = _success;

    final icon = success == null
        ? Icons.cloud_outlined
        : (success ? Icons.check_circle : Icons.error);
    final color = success == null
        ? Colors.grey
        : (success ? Colors.green : Colors.red);

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
              Text(
                _message ?? l10n.diagnosticsIntro,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loading ? null : _checkBackend,
                icon: _loading
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
