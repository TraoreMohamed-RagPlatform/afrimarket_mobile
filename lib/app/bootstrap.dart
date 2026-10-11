import 'package:afrimarket_mobile/app/app.dart';
import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/firebase_config.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/security/app_attestation.dart';
import 'package:afrimarket_mobile/core/security/firebase_app_attestation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Point de démarrage commun à tous les environnements.
///
/// 1. Lit et valide la configuration (arrêt immédiat si invalide).
/// 2. Initialise Firebase et App Check (preuve anti-robots).
/// 3. Rend la configuration disponible dans toute l'app via Riverpod.
/// 4. Lance l'application.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment(expected: flavor);
  final attestation = await initAppAttestation(
    flavor: flavor,
    config: FirebaseConfig.fromEnvironment(flavor: flavor),
  );

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appAttestationProvider.overrideWithValue(attestation),
      ],
      child: const AfriMarketApp(),
    ),
  );
}
