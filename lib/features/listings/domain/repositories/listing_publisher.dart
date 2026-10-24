import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_changes.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';

/// Contrat : publication et gestion de ses annonces (connexion requise).
///
/// Étapes séparées : l'annonce est créée masquée, les photos sont
/// envoyées, puis elle est publiée. Les cas d'usage enchaînent ces étapes.
abstract interface class ListingPublisher {
  /// Crée l'annonce MASQUÉE (invisible dans le fil). Renvoie son identifiant.
  Future<Result<String>> createHidden(ListingDraft draft);

  /// Envoie les photos, dans l'ordre (ajoutées après celles déjà en
  /// ligne). Renvoie les photos créées, dans le même ordre.
  Future<Result<List<RemotePhoto>>> uploadPhotos(
    String listingId,
    List<LocalPhoto> photos,
  );

  /// Rend l'annonce visible dans le fil.
  Future<Result<void>> publish(String listingId);

  /// Enregistre les champs modifiés.
  Future<Result<void>> update(String listingId, ListingChanges changes);

  /// Retire une photo en ligne.
  Future<Result<void>> deletePhoto(String listingId, String photoId);

  /// Nouvel ordre des photos (toutes, la première est la principale).
  Future<Result<void>> reorderPhotos(String listingId, List<String> photoIds);

  /// Supprime l'annonce (publication abandonnée, ou par le vendeur).
  Future<Result<void>> delete(String listingId);

  /// Réservée (badge « Réservé ») ou de nouveau disponible.
  Future<Result<void>> setReserved(String listingId, {required bool reserved});

  /// Vendue : retirée du fil, photos en noir et blanc.
  Future<Result<void>> markSold(String listingId);
}
