import 'package:afrimarket_mobile/app/app.dart';
import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Point de démarrage commun à tous les environnements.
///
/// 1. Lit et valide la configuration (arrêt immédiat si invalide).
/// 2. Rend la configuration disponible dans toute l'app via Riverpod.
/// 3. Lance l'application.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment(expected: flavor);

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const AfriMarketApp(),
    ),
  );
}
