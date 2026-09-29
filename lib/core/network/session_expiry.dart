import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signale que la session a expiré (refresh refusé par le serveur).
///
/// L'état est un simple compteur : chaque expiration l'incrémente.
/// La navigation l'écoute pour renvoyer l'utilisateur vers la connexion.
class SessionExpiryNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void notify() => state++;
}

final sessionExpiryProvider = NotifierProvider<SessionExpiryNotifier, int>(
  SessionExpiryNotifier.new,
);
