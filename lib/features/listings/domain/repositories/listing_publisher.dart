import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';

/// Contrat : publication et gestion de ses annonces (connexion requise).
///
/// Étapes séparées : l'annonce est créée masquée, les photos sont
/// envoyées, puis elle est publiée. Le cas d'usage enchaîne ces étapes.
abstract interface class ListingPublisher {
  /// Crée l'annonce MASQUÉE (invisible dans le fil). Renvoie son identifiant.
  Future<Result<String>> createHidden(ListingDraft draft);

  /// Envoie les photos, dans l'ordre (la première est la principale).
  Future<Result<void>> uploadPhotos(String listingId, List<LocalPhoto> photos);

  /// Rend l'annonce visible dans le fil.
  Future<Result<void>> publish(String listingId);

  /// Supprime l'annonce (publication abandonnée).
  Future<Result<void>> delete(String listingId);

  /// Réservée (badge « Réservé ») ou de nouveau disponible.
  Future<Result<void>> setReserved(String listingId, {required bool reserved});

  /// Vendue : retirée du fil, photos en noir et blanc.
  Future<Result<void>> markSold(String listingId);
}
