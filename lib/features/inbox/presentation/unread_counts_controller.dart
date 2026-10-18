import 'dart:async';

import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/inbox/domain/entities/unread_counts.dart';
import 'package:afrimarket_mobile/features/inbox/inbox_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pastilles de non-lus de la barre du bas.
///
/// - visiteur : toujours zéro, aucun appel au serveur ;
/// - connecté : lues dès la connexion, puis à chaque [refresh] (la barre du
///   bas l'appelle toutes les minutes, au retour dans l'app et à chaque
///   changement d'onglet) ;
/// - en cas d'échec, les derniers compteurs connus restent affichés ;
/// - à la déconnexion, retour à zéro.
class UnreadCountsController extends Notifier<UnreadCounts> {
  bool _loading = false;

  @override
  UnreadCounts build() {
    final signedIn = ref.watch(sessionProvider) == SessionStatus.authenticated;
    if (signedIn) unawaited(Future.microtask(refresh));
    return UnreadCounts.zero;
  }

  /// Relit les compteurs (sans effet pour un visiteur, ou si une lecture
  /// est déjà en cours).
  Future<void> refresh() async {
    if (_loading || !ref.mounted) return;
    if (ref.read(sessionProvider) != SessionStatus.authenticated) return;
    _loading = true;
    try {
      final result = await ref.read(getUnreadCountsUseCaseProvider)();
      if (!ref.mounted) return;
      // Déconnecté pendant la lecture : on n'affiche rien.
      if (ref.read(sessionProvider) != SessionStatus.authenticated) return;
      if (result case Ok(:final value)) state = value;
    } finally {
      _loading = false;
    }
  }
}

final NotifierProvider<UnreadCountsController, UnreadCounts>
unreadCountsProvider = NotifierProvider<UnreadCountsController, UnreadCounts>(
  UnreadCountsController.new,
);
