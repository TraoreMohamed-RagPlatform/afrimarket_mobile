import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Affiche [child] si l'utilisateur est connecté, sinon [signInPrompt].
///
/// Réagit en direct à la session : connexion (le contenu apparaît) ou
/// session expirée (l'invitation revient immédiatement).
///
/// Complète la garde de navigation pour les pages `signInPrompt`
/// (ADR 0002) ; ne protège pas les données : le serveur reste seul juge.
class AuthGate extends ConsumerWidget {
  const new({required this.signInPrompt, required this.child, super.key});

  final Widget signInPrompt;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(sessionProvider)) {
      SessionStatus.authenticated => child,
      SessionStatus.unauthenticated => signInPrompt,
      SessionStatus.unknown => const Center(child: CircularProgressIndicator()),
    };
  }
}
