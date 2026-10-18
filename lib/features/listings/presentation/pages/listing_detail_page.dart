import 'package:afrimarket_mobile/core/theme/app_spacing.dart';
import 'package:afrimarket_mobile/shared/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Détail d'une annonce (adresse `/listings/:id`, ouverte depuis le fil ou un
/// lien partagé).
///
/// PROVISOIRE : photos, description, vendeur et contact arrivent avec la page
/// Détail.
class ListingDetailPage extends StatelessWidget {
  const new({required this.listingId, super.key});

  /// Identifiant de l'annonce (déjà validé par `RouteAccessPolicy`).
  final String listingId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.listingDetailTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            l10n.listingDetailComingSoon,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
