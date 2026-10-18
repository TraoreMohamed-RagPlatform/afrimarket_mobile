import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/feed_filters.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listings_repository.dart';

/// Cas d'usage : charger une page du fil d'annonces.
class GetFeedUseCase {
  const new(this._repository);

  final ListingsRepository _repository;

  /// Une page inférieure à 1 est ramenée à 1. Des prix incohérents
  /// (maximum inférieur au minimum) sont ignorés plutôt que refusés.
  Future<Result<ListingPage>> call({
    int page = 1,
    String? categoryId,
    FeedFilters filters = FeedFilters.none,
  }) {
    return _repository.fetchFeed(
      page: page < 1 ? 1 : page,
      categoryId: categoryId,
      filters: filters.hasValidPrices
          ? filters
          : FeedFilters(
              city: filters.city,
              district: filters.district,
              sort: filters.sort,
            ),
    );
  }
}
