import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuration de l'environnement courant, accessible partout via Riverpod.
///
/// Sa vraie valeur est fournie au démarrage par `bootstrap()`.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider doit être fourni par bootstrap().',
  ),
);
