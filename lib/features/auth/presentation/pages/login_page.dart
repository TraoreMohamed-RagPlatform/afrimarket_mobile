import 'package:flutter/material.dart';

/// Écran de connexion.
///
/// PROVISOIRE (F1.7) : le formulaire de connexion arrive en F3.
/// Textes en dur migrés vers les traductions en F1.8.
class LoginPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Écran de connexion : disponible en F3',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
