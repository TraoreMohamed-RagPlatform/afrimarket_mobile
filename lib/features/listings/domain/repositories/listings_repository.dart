import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';

/// Contrat : lecture des annonces (fil, catégories).
///
/// Consultation sans compte (ADR 0002) : ces lectures ne demandent pas
/// d'être connecté.
abstract interface class ListingsRepository {
  /// Annonces actives, des plus récentes aux plus anciennes.
  ///
  /// [page] commence à 1. [categoryId] limite le fil à une catégorie.
  Future<Result<ListingPage>> fetchFeed({
    required int page,
    String? categoryId,
  });

  /// Catégories proposées dans le menu et la pastille « Catégories ».
  Future<Result<List<ListingCategory>>> fetchCategories();
}
