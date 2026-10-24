import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/feed_filters.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_photo.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_seller.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/report_reason.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/seller_contact.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listings_repository.dart';
import 'package:afrimarket_mobile/features/listings/listings_providers.dart';
import 'package:flutter_riverpod/misc.dart';

/// Réponse du faux serveur pour une page du fil.
typedef FeedAnswer = FutureOr<Result<ListingPage>> Function(
  int page,
  String? categoryId,
);

/// Faux dépôt d'annonces : réponses configurables, appels mémorisés.
///
/// Par défaut : un fil vide, aucune catégorie, une annonce introuvable,
/// aucune annonce similaire, aucun lieu, aucun numéro.
class FakeListingsRepository implements ListingsRepository {
  new({FeedAnswer? feed, this.categories = const Ok<List<ListingCategory>>([])})
    : feed = feed ?? emptyFeed;

  Result<ListingDetail> detail = const Err(NotFoundFailure());
  Result<List<ListingSummary>> similar = const Ok([]);
  Result<ListingLocations> locations = const Ok(ListingLocations.empty);
  Result<SellerContact> contact = const Err(NotFoundFailure());
  Result<void> report = const Ok(null);

  final detailCalls = <String>[];
  final contactCalls = <String>[];

  /// Signalements reçus : (annonce, motif, détail).
  final reports = <(String, ReportReason, String?)>[];

  /// Fil vide, quelle que soit la page.
  static Result<ListingPage> emptyFeed(int page, String? categoryId) =>
      Ok(ListingPage(items: const [], page: page, hasMore: false));

  FeedAnswer feed;
  Result<List<ListingCategory>> categories;

  /// Appels à `fetchFeed`, dans l'ordre : (page, catégorie).
  final feedCalls = <(int, String?)>[];

  /// Filtres reçus par `fetchFeed`, dans le même ordre que [feedCalls].
  final feedFilters = <FeedFilters>[];

  @override
  Future<Result<ListingPage>> fetchFeed({
    required int page,
    String? categoryId,
    FeedFilters filters = FeedFilters.none,
  }) {
    feedCalls.add((page, categoryId));
    feedFilters.add(filters);
    return Future.value(feed(page, categoryId));
  }

  @override
  Future<Result<List<ListingCategory>>> fetchCategories() async => categories;

  @override
  Future<Result<ListingDetail>> fetchListing(String id) async {
    detailCalls.add(id);
    return detail;
  }

  @override
  Future<Result<List<ListingSummary>>> fetchSimilar(String id) async => similar;

  @override
  Future<Result<ListingLocations>> fetchLocations() async => locations;

  @override
  Future<Result<SellerContact>> fetchSellerContact(String id) async {
    contactCalls.add(id);
    return contact;
  }

  @override
  Future<Result<void>> reportListing({
    required String id,
    required ReportReason reason,
    String? details,
  }) async {
    reports.add((id, reason, details));
    return report;
  }
}

/// Remplace le dépôt d'annonces de l'app par [repository] (fil vide par
/// défaut) : aucun test ne doit appeler le vrai serveur.
List<Override> listingsOverrides([FakeListingsRepository? repository]) => [
  listingsRepositoryProvider.overrideWithValue(
    repository ?? FakeListingsRepository(),
  ),
];

/// Annonce de test n° [index] (« Annonce 1 », 100 MAD, publiée il y a
/// 3 jours par défaut).
ListingSummary sampleListing(
  int index, {
  DateTime? createdAt,
  bool isSold = false,
  bool isReserved = false,
}) {
  return ListingSummary(
    id: 'l$index',
    title: 'Annonce $index',
    price: 100 * index,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(days: 3)),
    isSold: isSold,
    isReserved: isReserved,
  );
}

/// Page n° [page] de [count] annonces, numérotées à la suite.
ListingPage samplePage(int page, {int count = 20, bool hasMore = true}) {
  final first = (page - 1) * count + 1;
  return ListingPage(
    items: [for (var i = first; i < first + count; i++) sampleListing(i)],
    page: page,
    hasMore: hasMore,
  );
}

/// Vendeur de test : Aminata K., 4,8 sur 12 avis, identité vérifiée.
ListingSeller sampleSeller({
  bool canCall = true,
  bool canWhatsapp = true,
  int ratingCount = 12,
  int? responseTimeMinutes = 45,
}) {
  return ListingSeller(
    id: 'seller-1',
    name: 'Aminata K.',
    averageRating: 4.8,
    ratingCount: ratingCount,
    isIdentityVerified: true,
    memberSince: DateTime(2025, 3),
    responseTimeMinutes: responseTimeMinutes,
    canCall: canCall,
    canWhatsapp: canWhatsapp,
  );
}

/// Annonce complète de test : « Canapé 3 places, tissu gris », 1 200 DH
/// (1 500 DH avant), négociable, au Maârif.
ListingDetail sampleDetail({
  String id = 'listing-1',
  bool isSold = false,
  bool isReserved = false,
  bool isOwner = false,
  bool isNegotiable = true,
  num? previousPrice = 1500,
  String description =
      'Canapé acheté il y a deux ans chez un artisan de Derb Omar. '
      'Structure en bois massif, housse lavable.',
  ListingSeller? seller,
  List<String> imageUrls = const [],
  List<RemotePhoto> photos = const [],
  ListingCategory? category,
}) {
  return ListingDetail(
    id: id,
    title: 'Canapé 3 places, tissu gris',
    description: description,
    price: 1200,
    previousPrice: previousPrice,
    isNegotiable: isNegotiable,
    isSold: isSold,
    isReserved: isReserved,
    isOwner: isOwner,
    condition: ListingCondition.good,
    categoryName: 'Mobilier',
    city: 'casablanca',
    district: 'maarif',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    imageUrls: imageUrls,
    photos: photos,
    category: category,
    seller: seller ?? sampleSeller(),
  );
}

/// Villes et quartiers de test : Casablanca (Maârif, Ain Diab).
const sampleLocations = ListingLocations({
  'casablanca': (
    name: 'Casablanca',
    districts: {'maarif': 'Maârif', 'ain-diab': 'Ain Diab'},
  ),
});
