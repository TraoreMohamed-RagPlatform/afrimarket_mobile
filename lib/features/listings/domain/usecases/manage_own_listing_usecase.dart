import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listing_publisher.dart';

/// Cas d'usage : actions du vendeur sur sa propre annonce.
///
/// Le serveur vérifie que la personne connectée est bien le vendeur.
class ManageOwnListingUseCase {
  const new(this._publisher);

  final ListingPublisher _publisher;

  /// Réservée (un acheteur est en discussion) ou de nouveau disponible.
  Future<Result<void>> setReserved(String id, {required bool reserved}) =>
      _publisher.setReserved(id, reserved: reserved);

  /// Vendue : action définitive pour l'annonce.
  Future<Result<void>> markSold(String id) => _publisher.markSold(id);
}
