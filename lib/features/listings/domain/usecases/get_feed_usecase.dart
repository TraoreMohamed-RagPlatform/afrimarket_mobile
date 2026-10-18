import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listings_repository.dart';

/// Cas d'usage : charger une page du fil d'annonces.
class GetFeedUseCase {
  const new(this._repository);

  final ListingsRepository _repository;

  /// Une page inférieure à 1 est ramenée à 1.
  Future<Result<ListingPage>> call({int page = 1, String? categoryId}) {
    return _repository.fetchFeed(
      page: page < 1 ? 1 : page,
      categoryId: categoryId,
    );
  }
}
