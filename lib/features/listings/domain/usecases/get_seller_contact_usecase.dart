import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/seller_contact.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listings_repository.dart';

/// Cas d'usage : obtenir le numéro du vendeur (connexion requise).
class GetSellerContactUseCase {
  const new(this._repository);

  final ListingsRepository _repository;

  Future<Result<SellerContact>> call(String listingId) =>
      _repository.fetchSellerContact(listingId);
}
