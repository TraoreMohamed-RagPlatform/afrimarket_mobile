import 'package:afrimarket_mobile/core/error/result.dart';

/// Contrat : annonces enregistrées (connexion requise).
abstract interface class FavoritesRepository {
  /// Vrai si l'utilisateur a enregistré l'annonce [listingId].
  Future<Result<bool>> isFavorite(String listingId);

  /// Enregistre l'annonce. Déjà enregistrée : réussi.
  Future<Result<void>> add(String listingId);

  /// Retire l'annonce. Déjà retirée : réussi.
  Future<Result<void>> remove(String listingId);
}
