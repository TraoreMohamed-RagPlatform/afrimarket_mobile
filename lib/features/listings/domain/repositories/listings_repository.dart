import 'package:afrimarket_mobile/core/error/failure.dart' show NotFoundFailure;
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/report_reason.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/seller_contact.dart';

/// Contrat : annonces (fil, catégories, détail).
///
/// Consultation sans compte (ADR 0002) : les lectures ne demandent pas
/// d'être connecté, sauf le numéro du vendeur et le signalement.
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

  /// Annonce complète. [NotFoundFailure] si elle n'existe pas (ou plus).
  Future<Result<ListingDetail>> fetchListing(String id);

  /// Annonces de la même catégorie, celles du même quartier d'abord.
  Future<Result<List<ListingSummary>>> fetchSimilar(String id);

  /// Villes et quartiers, pour afficher le lieu d'une annonce.
  Future<Result<ListingLocations>> fetchLocations();

  /// Numéro du vendeur (connexion requise). [NotFoundFailure] si le
  /// vendeur ne le partage pas, ou plus.
  Future<Result<SellerContact>> fetchSellerContact(String id);

  /// Signale l'annonce à la modération (connexion requise).
  ///
  /// Un second signalement de la même personne est considéré comme
  /// réussi : il a déjà été pris en compte.
  Future<Result<void>> reportListing({
    required String id,
    required ReportReason reason,
    String? details,
  });
}
