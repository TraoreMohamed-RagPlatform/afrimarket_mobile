import 'package:meta/meta.dart';

/// Tri du fil (mêmes valeurs que le serveur).
enum FeedSort {
  newest('newest'),
  priceAsc('price_asc'),
  priceDesc('price_desc');

  new(this.apiValue);

  /// Valeur du paramètre `sort` envoyé au serveur.
  final String apiValue;
}

/// Filtres du fil, en plus de la catégorie : quartier, tri, prix.
///
/// Entité métier : Dart pur.
@immutable
final class FeedFilters {
  const new({
    this.city,
    this.district,
    this.sort = FeedSort.newest,
    this.minPrice,
    this.maxPrice,
  });

  /// Aucun filtre : toutes les annonces, les plus récentes d'abord.
  static const none = FeedFilters();

  /// Identifiants de la liste fixe du serveur (« casablanca », « maarif »).
  final String? city;
  final String? district;

  final FeedSort sort;

  /// Prix en dirhams ; null = sans limite.
  final num? minPrice;
  final num? maxPrice;

  /// Nombre de filtres choisis (pastille « Filtres · 2 »).
  int get activeCount =>
      (district != null ? 1 : 0) +
      (sort != FeedSort.newest ? 1 : 0) +
      (minPrice != null || maxPrice != null ? 1 : 0);

  bool get isActive => activeCount > 0;

  /// Vrai si les prix sont cohérents (maximum au moins égal au minimum).
  bool get hasValidPrices {
    final min = minPrice;
    final max = maxPrice;
    return (min == null || min >= 0) &&
        (max == null || max >= 0) &&
        (min == null || max == null || max >= min);
  }

  @override
  bool operator ==(Object other) =>
      other is FeedFilters &&
      other.city == city &&
      other.district == district &&
      other.sort == sort &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice;

  @override
  int get hashCode => Object.hash(city, district, sort, minPrice, maxPrice);
}
