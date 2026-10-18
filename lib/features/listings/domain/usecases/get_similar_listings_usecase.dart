import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listings_repository.dart';

/// Cas d'usage : annonces similaires à une annonce.
class GetSimilarListingsUseCase {
  const new(this._repository);

  final ListingsRepository _repository;

  /// L'annonce elle-même n'est jamais proposée.
  Future<Result<List<ListingSummary>>> call(String id) async {
    final result = await _repository.fetchSimilar(id);
    return result.map(
      (items) => [
        for (final item in items)
          if (item.id != id) item,
      ],
    );
  }
}
