import 'package:afrimarket_mobile/core/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Affichée pour toute route inconnue.
///
/// Volontairement générique : l'adresse demandée n'est pas affichée.
class NotFoundPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Page introuvable'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Retour à l’accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
