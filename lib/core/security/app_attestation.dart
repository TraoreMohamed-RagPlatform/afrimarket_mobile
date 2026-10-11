import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preuve que les requêtes sensibles viennent de la vraie application
/// AfriMarket (et pas d'un robot) : jeton Firebase App Check.
///
/// Abstraction : le reste de l'application ne dépend pas de Firebase,
/// et les tests utilisent une fausse implémentation.
abstract interface class AppAttestation {
  /// Jeton App Check à usage unique pour notre backend (protection contre
  /// le rejeu), ou `null` si aucun jeton ne peut être obtenu.
  Future<String?> limitedUseToken();
}

/// Aucune attestation disponible (Firebase non configuré en développement).
/// Le backend refusera alors la connexion et l'inscription (403).
final class NoAppAttestation implements AppAttestation {
  const new();

  @override
  Future<String?> limitedUseToken() async => null;
}

/// Attestation de l'environnement courant.
///
/// Sa vraie valeur est fournie au démarrage par `bootstrap()`.
final appAttestationProvider = Provider<AppAttestation>(
  (ref) => const NoAppAttestation(),
);
