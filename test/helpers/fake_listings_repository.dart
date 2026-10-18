import 'dart:async';

import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
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
/// Par défaut : un fil vide et aucune catégorie.
class FakeListingsRepository implements ListingsRepository {
  new({FeedAnswer? feed, this.categories = const Ok<List<ListingCategory>>([])})
    : feed = feed ?? emptyFeed;

  /// Fil vide, quelle que soit la page.
  static Result<ListingPage> emptyFeed(int page, String? categoryId) =>
      Ok(ListingPage(items: const [], page: page, hasMore: false));

  FeedAnswer feed;
  Result<List<ListingCategory>> categories;

  /// Appels à `fetchFeed`, dans l'ordre : (page, catégorie).
  final feedCalls = <(int, String?)>[];

  @override
  Future<Result<ListingPage>> fetchFeed({
    required int page,
    String? categoryId,
  }) {
    feedCalls.add((page, categoryId));
    return Future.value(feed(page, categoryId));
  }

  @override
  Future<Result<List<ListingCategory>>> fetchCategories() async => categories;
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
}) {
  return ListingSummary(
    id: 'l$index',
    title: 'Annonce $index',
    price: 100 * index,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(days: 3)),
    isSold: isSold,
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
