import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/favorites/domain/repositories/favorites_repository.dart';

/// Cas d'usage : savoir si une annonce est enregistrée.
class GetFavoriteStatusUseCase {
  const new(this._repository);

  final FavoritesRepository _repository;

  Future<Result<bool>> call(String listingId) =>
      _repository.isFavorite(listingId);
}
