import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/feed_filters.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/feed_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_listings_repository.dart';

const _housing = ListingCategory(id: 'c1', name: 'Logement');

void main() {
  late FakeListingsRepository repository;
  late ProviderContainer container;

  FeedState state() => container.read(feedControllerProvider);
  FeedController feed() => container.read(feedControllerProvider.notifier);

  /// Démarre le fil et attend la première page.
  Future<void> start() async {
    container.listen(feedControllerProvider, (_, _) {});
    await pumpEventQueue();
  }

  setUp(() {
    repository = FakeListingsRepository();
    container = ProviderContainer(overrides: listingsOverrides(repository));
    addTearDown(container.dispose);
  });

  group('Premier chargement', () {
    test('squelettes, puis les annonces', () async {
      repository.feed = (page, _) => Ok(samplePage(page));

      expect(state().phase, FeedPhase.loading);
      await start();

      expect(state().phase, FeedPhase.ready);
      expect(state().items, hasLength(20));
      expect(state().hasMore, isTrue);
      expect(repository.feedCalls, [(1, null)]);
    });

    test('fil vide', () async {
      await start();

      expect(state().isEmpty, isTrue);
      expect(state().canLoadMore, isFalse);
    });

    test('erreur : écran d’erreur', () async {
      repository.feed = (_, _) => const Err(NetworkFailure());

      await start();

      expect(state().phase, FeedPhase.failed);
      expect(state().failure, isA<NetworkFailure>());
    });

    test('« Réessayer » après une erreur', () async {
      repository.feed = (_, _) => const Err(NetworkFailure());
      await start();

      repository.feed = (page, _) => Ok(samplePage(page));
      final retry = feed().refresh();
      expect(state().phase, FeedPhase.loading);
      await retry;

      expect(state().phase, FeedPhase.ready);
      expect(state().items, hasLength(20));
    });
  });

  group('Défilement infini', () {
    test('ajoute la page suivante', () async {
      repository.feed = (page, _) => Ok(samplePage(page, hasMore: page < 2));
      await start();

      await feed().loadMore();

      expect(state().items, hasLength(40));
      expect(state().items.last.id, 'l40');
      expect(state().hasMore, isFalse);
      expect(repository.feedCalls, [(1, null), (2, null)]);
    });

    test('plus rien à charger : aucun appel', () async {
      repository.feed = (page, _) => Ok(samplePage(page, hasMore: false));
      await start();

      await feed().loadMore();

      expect(repository.feedCalls, [(1, null)]);
    });

    test('un seul chargement à la fois', () async {
      final second = Completer<Result<ListingPage>>();
      repository.feed = (page, _) async =>
          page == 1 ? Ok(samplePage(1)) : await second.future;
      await start();

      final first = feed().loadMore();
      unawaited(feed().loadMore());
      expect(state().isLoadingMore, isTrue);
      second.complete(Ok(samplePage(2)));
      await first;

      expect(repository.feedCalls, [(1, null), (2, null)]);
    });

    test('annonce déjà affichée (pages décalées) : pas de doublon', () async {
      repository.feed = (page, _) => page == 1
          ? Ok(samplePage(1, count: 2))
          : Ok(
              ListingPage(
                items: [sampleListing(2), sampleListing(3)],
                page: 2,
                hasMore: false,
              ),
            );
      await start();

      await feed().loadMore();

      expect(state().items.map((item) => item.id), ['l1', 'l2', 'l3']);
    });

    test(
      'erreur de page suivante : le fil reste, puis « Réessayer »',
      () async {
        repository.feed = (page, _) =>
            page == 1 ? Ok(samplePage(1)) : const Err(TimeoutFailure());
        await start();

        await feed().loadMore();
        expect(state().items, hasLength(20));
        expect(state().loadMoreFailure, isA<TimeoutFailure>());
        expect(state().canLoadMore, isFalse);

        repository.feed = (page, _) => Ok(samplePage(page, hasMore: false));
        await feed().retryLoadMore();

        expect(state().loadMoreFailure, isNull);
        expect(state().items, hasLength(40));
      },
    );
  });

  group('Actualiser', () {
    test('remplace le fil par la première page', () async {
      repository.feed = (page, _) => Ok(samplePage(page));
      await start();
      await feed().loadMore();

      await feed().refresh();

      expect(state().items, hasLength(20));
      expect(repository.feedCalls.last, (1, null));
    });

    test('pendant l’actualisation, les annonces restent visibles', () async {
      repository.feed = (page, _) => Ok(samplePage(page));
      await start();

      final pending = Completer<Result<ListingPage>>();
      repository.feed = (_, _) => pending.future;
      final refresh = feed().refresh();

      expect(state().phase, FeedPhase.ready);
      expect(state().items, hasLength(20));
      pending.complete(Ok(samplePage(1, count: 5)));
      await refresh;
      expect(state().items, hasLength(5));
    });

    test(
      'échec : les annonces restent, le message est signalé une fois',
      () async {
        repository.feed = (page, _) => Ok(samplePage(page));
        await start();

        repository.feed = (_, _) => const Err(NetworkFailure());
        await feed().refresh();

        expect(state().phase, FeedPhase.ready);
        expect(state().items, hasLength(20));
        expect(state().refreshFailure, isA<NetworkFailure>());

        feed().refreshFailureShown();
        expect(state().refreshFailure, isNull);
      },
    );
  });

  group('Catégorie', () {
    test('filtre le fil', () async {
      repository.feed = (page, category) => Ok(samplePage(page));
      await start();

      final select = feed().selectCategory(_housing);
      expect(state().phase, FeedPhase.loading);
      expect(state().category, _housing);
      await select;

      expect(state().phase, FeedPhase.ready);
      expect(repository.feedCalls.last, (1, 'c1'));
    });

    test('la page suivante garde la catégorie', () async {
      repository.feed = (page, _) => Ok(samplePage(page));
      await start();
      await feed().selectCategory(_housing);

      await feed().loadMore();

      expect(repository.feedCalls.last, (2, 'c1'));
    });

    test('même catégorie : aucun rechargement', () async {
      await start();

      await feed().selectCategory(null);

      expect(repository.feedCalls, [(1, null)]);
    });

    test('une réponse arrivée trop tard est ignorée', () async {
      final slow = Completer<Result<ListingPage>>();
      repository.feed = (page, category) async => category == null
          ? await slow.future
          : Ok(samplePage(1, count: 3, hasMore: false));
      container.listen(feedControllerProvider, (_, _) {});

      await feed().selectCategory(_housing);
      slow.complete(Ok(samplePage(1)));
      await pumpEventQueue();

      expect(state().category, _housing);
      expect(state().items, hasLength(3));
    });
  });

  group('Filtres', () {
    const maarif = FeedFilters(city: 'casablanca', district: 'maarif');

    test(
      'appliquer : rechargement depuis la page 1 avec les filtres',
      () async {
        repository.feed = (page, _) => Ok(samplePage(page));
        await start();

        final apply = feed().applyFilters(maarif);
        expect(state().phase, FeedPhase.loading);
        await apply;

        expect(state().filters, maarif);
        expect(state().isFiltered, isTrue);
        expect(repository.feedCalls.last, (1, null));
        expect(repository.feedFilters.last, maarif);
      },
    );

    test('la catégorie est gardée quand on change les filtres', () async {
      await start();
      await feed().selectCategory(_housing);

      await feed().applyFilters(maarif);

      expect(state().category, _housing);
      expect(repository.feedCalls.last, (1, 'c1'));
    });

    test('les filtres sont gardés quand on change de catégorie', () async {
      await start();
      await feed().applyFilters(maarif);

      await feed().selectCategory(_housing);

      expect(state().filters, maarif);
      expect(repository.feedFilters.last, maarif);
    });

    test('page suivante et actualisation gardent les filtres', () async {
      repository.feed = (page, _) => Ok(samplePage(page, hasMore: page < 2));
      await start();
      await feed().applyFilters(maarif);

      await feed().loadMore();
      await feed().refresh();

      expect(repository.feedFilters.skip(1), everyElement(maarif));
    });

    test('mêmes filtres : aucun rechargement', () async {
      await start();

      await feed().applyFilters(FeedFilters.none);

      expect(repository.feedCalls, hasLength(1));
    });

    test('« Voir toutes les annonces » retire catégorie et filtres', () async {
      await start();
      await feed().selectCategory(_housing);
      await feed().applyFilters(maarif);

      await feed().clearFilters();

      expect(state().category, isNull);
      expect(state().filters, FeedFilters.none);
      expect(state().isFiltered, isFalse);
      expect(repository.feedCalls.last, (1, null));
      expect(repository.feedFilters.last, FeedFilters.none);
    });

    test('rien à retirer : aucun rechargement', () async {
      await start();

      await feed().clearFilters();

      expect(repository.feedCalls, hasLength(1));
    });
  });
}
