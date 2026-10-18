import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:afrimarket_mobile/features/listings/data/datasources/listings_remote_datasource.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
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
  }) {
    return guardApiCall(
      () => _remote.fetchFeed(
        page: page,
        limit: pageSize,
        categoryId: categoryId,
      ),
    );
  }

  @override
  Future<Result<List<ListingCategory>>> fetchCategories() {
    return guardApiCall(_remote.fetchCategories);
  }
}
