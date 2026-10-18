import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listings_repository.dart';

/// Cas d'usage : lister les catégories d'annonces.
class GetCategoriesUseCase {
  const new(this._repository);

  final ListingsRepository _repository;

  Future<Result<List<ListingCategory>>> call() => _repository.fetchCategories();
}
