import 'dart:async';

import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/features/auth/presentation/controllers/sign_out.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Mon profil (bouton 👤 du fil, menu ☰).
///
/// Réservée aux utilisateurs connectés : un visiteur est envoyé vers la
/// connexion par la garde de navigation (`RouteAccess.authenticated`).
///
/// PROVISOIRE : l'édition du profil arrive avec la fonctionnalité Profil.
/// La déconnexion, elle, est déjà disponible ici.
class MyProfilePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myProfileTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.profileComingSoon, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () {
                  final signOut = ref.read(signOutProvider);
                  // Retour au fil d'abord : sans cela, la garde de
                  // navigation renverrait vers la connexion (page protégée).
                  context.go(AppRoutes.home);
                  unawaited(signOut());
                },
                icon: const Icon(AppIcons.signOut),
                label: Text(l10n.logoutTooltip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
