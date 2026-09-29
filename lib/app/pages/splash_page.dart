import 'package:flutter/material.dart';

/// Affichée pendant la vérification de la session au démarrage.
class SplashPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(semanticsLabel: 'Chargement'),
      ),
    );
  }
}
