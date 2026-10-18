import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/get_categories_usecase.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/get_feed_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_listings_repository.dart';

void main() {
  group('ListingSummary.isRecentAt', () {
    final now = DateTime(2026, 10, 18, 12);

    ListingSummary at(DateTime createdAt) => ListingSummary(
      id: 'l1',
      title: 'Lit',
      price: 700,
      createdAt: createdAt,
    );

    test('moins de 24 h : récente', () {
      expect(at(now.subtract(const Duration(hours: 23))).isRecentAt(now), true);
    });

    test('24 h ou plus : pas récente', () {
      expect(
        at(now.subtract(const Duration(hours: 24))).isRecentAt(now),
        false,
      );
    });

    test('date dans le futur : pas récente', () {
      expect(at(now.add(const Duration(hours: 1))).isRecentAt(now), false);
    });

    test('égalité par valeur', () {
      expect(at(now), at(now));
      expect(at(now).hashCode, at(now).hashCode);
    });
  });

  group('Cas d’usage', () {
    test('GetFeedUseCase : page ramenée à 1 au minimum', () async {
      final repository = FakeListingsRepository();

      await GetFeedUseCase(repository)(page: 0, categoryId: 'c1');
      await GetFeedUseCase(repository)(page: 3);

      expect(repository.feedCalls, [(1, 'c1'), (3, null)]);
    });

    test('GetCategoriesUseCase : transmet la réponse du dépôt', () async {
      final repository = FakeListingsRepository();

      final result = await GetCategoriesUseCase(repository)();

      expect(result, same(repository.categories));
    });
  });
}
