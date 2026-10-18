import 'package:afrimarket_mobile/features/listings/domain/entities/feed_filters.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/get_feed_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_listings_repository.dart';

void main() {
  group('FeedFilters', () {
    test('aucun filtre par défaut', () {
      expect(FeedFilters.none.isActive, isFalse);
      expect(FeedFilters.none.activeCount, 0);
      expect(FeedFilters.none.sort, FeedSort.newest);
    });

    test('compte quartier, tri et prix (un seul pour min + max)', () {
      const filters = FeedFilters(
        city: 'casablanca',
        district: 'maarif',
        sort: FeedSort.priceDesc,
        minPrice: 100,
        maxPrice: 500,
      );

      expect(filters.activeCount, 3);
      expect(const FeedFilters(maxPrice: 500).activeCount, 1);
    });

    test('prix : maximum inférieur au minimum = incohérent', () {
      expect(
        const FeedFilters(minPrice: 500, maxPrice: 100).hasValidPrices,
        isFalse,
      );
      expect(
        const FeedFilters(minPrice: 100, maxPrice: 100).hasValidPrices,
        isTrue,
      );
      expect(const FeedFilters(minPrice: -1).hasValidPrices, isFalse);
    });

    test('valeurs du serveur pour le tri', () {
      expect(FeedSort.values.map((sort) => sort.apiValue), [
        'newest',
        'price_asc',
        'price_desc',
      ]);
    });

    test('égalité par valeur', () {
      expect(
        const FeedFilters(district: 'maarif', minPrice: 1),
        const FeedFilters(district: 'maarif', minPrice: 1),
      );
      expect(
        const FeedFilters(district: 'maarif').hashCode,
        const FeedFilters(district: 'maarif').hashCode,
      );
      expect(
        const FeedFilters(district: 'maarif'),
        isNot(const FeedFilters(district: 'oasis')),
      );
    });
  });

  group('GetFeedUseCase et filtres', () {
    test('filtres transmis tels quels', () async {
      final repository = FakeListingsRepository();
      const filters = FeedFilters(
        city: 'casablanca',
        district: 'maarif',
        sort: FeedSort.priceAsc,
        minPrice: 100,
      );

      await GetFeedUseCase(repository)(filters: filters);

      expect(repository.feedFilters.single, filters);
    });

    test('prix incohérents ignorés, quartier et tri gardés', () async {
      final repository = FakeListingsRepository();

      await GetFeedUseCase(repository)(
        filters: const FeedFilters(
          city: 'casablanca',
          district: 'maarif',
          sort: FeedSort.priceDesc,
          minPrice: 900,
          maxPrice: 100,
        ),
      );

      expect(
        repository.feedFilters.single,
        const FeedFilters(
          city: 'casablanca',
          district: 'maarif',
          sort: FeedSort.priceDesc,
        ),
      );
    });
  });

  group('ListingLocations', () {
    test('nom de ville et quartiers triés par nom', () {
      expect(sampleLocations.cities, ['casablanca']);
      expect(sampleLocations.cityName('casablanca'), 'Casablanca');
      expect(sampleLocations.cityName('rabat'), isNull);
      expect(sampleLocations.districtsOf('casablanca'), [
        (slug: 'ain-diab', name: 'Ain Diab'),
        (slug: 'maarif', name: 'Maârif'),
      ]);
      expect(sampleLocations.districtsOf('rabat'), isEmpty);
    });
  });
}
