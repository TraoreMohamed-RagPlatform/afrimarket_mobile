import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/favorites/domain/repositories/favorites_repository.dart';

/// Cas d'usage : enregistrer (`saved` vrai) ou retirer une annonce.
class SetFavoriteUseCase {
  const new(this._repository);

  final FavoritesRepository _repository;

  Future<Result<void>> call(String listingId, {required bool saved}) =>
      saved ? _repository.add(listingId) : _repository.remove(listingId);
}
