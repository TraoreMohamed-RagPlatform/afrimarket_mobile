import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Publication d'une annonce (plein écran, par-dessus les onglets).
///
/// Réservée aux utilisateurs connectés : la garde de navigation y veille
/// (`RouteAccess.authenticated`, par défaut).
///
/// PROVISOIRE : le parcours « photo d'abord » arrive en F5.
class PublishListingPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.publishTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.publishComingSoon, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
