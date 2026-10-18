import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listings_repository.dart';

/// Cas d'usage : villes et quartiers (noms à afficher).
class GetListingLocationsUseCase {
  const new(this._repository);

  final ListingsRepository _repository;

  Future<Result<ListingLocations>> call() => _repository.fetchLocations();
}
