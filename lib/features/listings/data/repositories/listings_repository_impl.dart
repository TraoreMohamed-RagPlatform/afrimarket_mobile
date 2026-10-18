import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:afrimarket_mobile/features/listings/data/datasources/listings_remote_datasource.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/feed_filters.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/report_reason.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/seller_contact.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listings_repository.dart';

/// Implémentation du contrat [ListingsRepository].
class ListingsRepositoryImpl implements ListingsRepository {
  const new(this._remote);

  /// Annonces par page : remplit plusieurs écrans de grille sans charger
  /// trop de photos d'un coup (économie de données).
  static const pageSize = 20;

  final ListingsRemoteDataSource _remote;

  @override
  Future<Result<ListingPage>> fetchFeed({
    required int page,
    String? categoryId,
    FeedFilters filters = FeedFilters.none,
  }) {
    return guardApiCall(
      () => _remote.fetchFeed(
        page: page,
        limit: pageSize,
        categoryId: categoryId,
        filters: filters,
      ),
    );
  }

  @override
  Future<Result<List<ListingCategory>>> fetchCategories() {
    return guardApiCall(_remote.fetchCategories);
  }

  @override
  Future<Result<ListingDetail>> fetchListing(String id) {
    return guardApiCall(() => _remote.fetchListing(id));
  }

  @override
  Future<Result<List<ListingSummary>>> fetchSimilar(String id) {
    return guardApiCall(() => _remote.fetchSimilar(id));
  }

  @override
  Future<Result<ListingLocations>> fetchLocations() {
    return guardApiCall(_remote.fetchLocations);
  }

  @override
  Future<Result<SellerContact>> fetchSellerContact(String id) {
    return guardApiCall(() => _remote.fetchSellerContact(id));
  }

  @override
  Future<Result<void>> reportListing({
    required String id,
    required ReportReason reason,
    String? details,
  }) {
    return guardApiCall(
      () => _remote.reportListing(id: id, reason: reason, details: details),
    );
  }
}
