import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:afrimarket_mobile/features/favorites/data/datasources/favorites_remote_datasource.dart';
import 'package:afrimarket_mobile/features/favorites/domain/repositories/favorites_repository.dart';

/// Implémentation du contrat [FavoritesRepository].
class FavoritesRepositoryImpl implements FavoritesRepository {
  const new(this._remote);

  final FavoritesRemoteDataSource _remote;

  @override
  Future<Result<bool>> isFavorite(String listingId) =>
      guardApiCall(() => _remote.isFavorite(listingId));

  @override
  Future<Result<void>> add(String listingId) =>
      guardApiCall(() => _remote.add(listingId));

  @override
  Future<Result<void>> remove(String listingId) =>
      guardApiCall(() => _remote.remove(listingId));
}
