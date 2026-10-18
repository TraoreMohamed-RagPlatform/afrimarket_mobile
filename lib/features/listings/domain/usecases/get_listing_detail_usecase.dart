import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listings_repository.dart';

/// Cas d'usage : charger une annonce complète (page de détail).
class GetListingDetailUseCase {
  const new(this._repository);

  final ListingsRepository _repository;

  Future<Result<ListingDetail>> call(String id) => _repository.fetchListing(id);
}
