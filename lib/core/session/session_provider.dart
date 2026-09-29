import 'dart:async';

import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/session_expiry.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État de la session utilisateur.
enum SessionStatus {
  /// Vérification en cours (démarrage de l'app).
  unknown,

  /// L'utilisateur est connecté.
  authenticated,

  /// L'utilisateur n'est pas connecté (ou sa session a expiré).
  unauthenticated,
}

/// Source de vérité de la session, utilisée par la navigation.
///
/// Sécurité (OWASP MASVS - AUTH) :
/// - « fermé par défaut » : une erreur de stockage donne `unauthenticated` ;
/// - une session expirée (refresh refusé) déconnecte automatiquement ;
/// - à la déconnexion, l'état change AVANT l'effacement des tokens,
///   pour masquer immédiatement les pages protégées.
class SessionNotifier extends Notifier<SessionStatus> {
  @override
  SessionStatus build() {
    ref.listen<int>(sessionExpiryProvider, (previous, next) {
      if (next != previous) state = SessionStatus.unauthenticated;
    });

    unawaited(_restore());
    return SessionStatus.unknown;
  }

  /// Vérifie au démarrage si une session existe dans le stockage.
  Future<void> _restore() async {
    final result = await ref.read(tokenStorageProvider).hasTokens();
    if (!ref.mounted) return;

    // Ne pas écraser une connexion survenue pendant la vérification.
    if (state != SessionStatus.unknown) return;

    state = switch (result) {
      Ok(value: true) => SessionStatus.authenticated,
      _ => SessionStatus.unauthenticated,
    };
  }

  /// À appeler après une connexion réussie (tokens déjà enregistrés).
  void markAuthenticated() {
    state = SessionStatus.authenticated;
  }

  /// Déconnexion locale : masque d'abord les pages, puis efface les tokens.
  Future<void> logout() async {
    state = SessionStatus.unauthenticated;
    await ref.read(tokenStorageProvider).clear();
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionStatus>(
  SessionNotifier.new,
);
