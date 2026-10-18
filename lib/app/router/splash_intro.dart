import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indique si l'animation du logo de l'écran de démarrage est terminée.
///
/// Le routeur garde l'écran de démarrage tant qu'elle joue (1,2 s au
/// plus), même si la session est déjà connue : l'animation n'est jamais
/// coupée, et l'app ne l'attend pas davantage (la session est vérifiée
/// en parallèle).
class SplashIntroNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// À appeler à la fin de l'animation (ou tout de suite si les
  /// animations sont réduites).
  void markFinished() {
    state = true;
  }
}

final splashIntroFinishedProvider = NotifierProvider<SplashIntroNotifier, bool>(
  SplashIntroNotifier.new,
);
