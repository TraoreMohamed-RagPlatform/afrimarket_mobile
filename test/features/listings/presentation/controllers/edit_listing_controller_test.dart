import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_changes.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/domain/listing_conflicts.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/edit_listing_usecase.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/edit_listing_controller.dart';
import 'package:afrimarket_mobile/features/listings/presentation/controllers/listing_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_listings_repository.dart';
import '../../../../helpers/fake_publish.dart';

const _p1 = RemotePhoto(id: 'p1', url: 'test://p1');
const _p2 = RemotePhoto(id: 'p2', url: 'test://p2');
const _mobilier = ListingCategory(id: 'c1', name: 'Mobilier');

ListingDetail _mine({bool isSold = false, bool isOwner = true}) => sampleDetail(
  isOwner: isOwner,
  isSold: isSold,
  photos: const [_p1, _p2],
  category: _mobilier,
);

/// Laisse passer les tâches en attente (chargements simulés).
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeListingsRepository listings;
  late FakeListingPublisher publisher;
  late FakePhotoPicker picker;
  final provider = editListingControllerProvider('listing-1');

  setUp(() {
    listings = FakeListingsRepository()..detail = Ok(_mine());
    publisher = FakeListingPublisher();
    picker = FakePhotoPicker();
  });

  Future<ProviderContainer> start() async {
    final container = ProviderContainer(
      overrides: [
        ...listingsOverrides(listings),
        ...publishOverrides(publisher: publisher, picker: picker),
      ],
    )..listen(provider, (_, _) {});
    addTearDown(container.dispose);
    await _settle();
    return container;
  }

  group('Lecture', () {
    test(
      'annonce du vendeur : formulaire rempli, rien à enregistrer',
      () async {
        final c = await start();
        final state = c.read(provider);

        expect(state.phase, EditPhase.ready);
        expect(state.draft.title, 'Canapé 3 places, tissu gris');
        expect(state.draft.photos, const [_p1, _p2]);
        expect(state.category, _mobilier);
        expect(state.revision, 1);
        expect(state.hasChanges, isFalse);
        expect(listings.detailCalls, ['listing-1']);
      },
    );

    test('annonce d’un autre : indisponible', () async {
      listings.detail = Ok(_mine(isOwner: false));
      final c = await start();

      expect(c.read(provider).phase, EditPhase.unavailable);
    });

    test('vendue : plus modifiable', () async {
      listings.detail = Ok(_mine(isSold: true));
      final c = await start();

      expect(c.read(provider).phase, EditPhase.sold);
    });

    test('introuvable : indisponible', () async {
      listings.detail = const Err(NotFoundFailure());
      final c = await start();

      expect(c.read(provider).phase, EditPhase.unavailable);
    });

    test('erreur réseau, puis « Réessayer »', () async {
      listings.detail = const Err(NetworkFailure());
      final c = await start();
      expect(c.read(provider).phase, EditPhase.failed);
      expect(c.read(provider).loadFailure, isA<NetworkFailure>());

      listings.detail = Ok(_mine());
      await c.read(provider.notifier).retry();

      expect(c.read(provider).phase, EditPhase.ready);
    });
  });

  group('Saisie', () {
    test(
      'changement puis retour à l’identique : plus rien à enregistrer',
      () async {
        final c = await start();
        final controller = c.read(provider.notifier)..setPrice('900');
        expect(c.read(provider).hasChanges, isTrue);

        controller.setPrice('1200');
        expect(c.read(provider).hasChanges, isFalse);
      },
    );

    test('photos : ajout, principale, retrait', () async {
      final c = await start();
      final controller = c.read(provider.notifier);

      expect(await controller.takePhoto(), PhotoAddOutcome.ok);
      controller
        ..makeMainPhoto(2)
        ..removePhoto(1);

      expect(c.read(provider).draft.photos, const [
        LocalPhoto('/photos/camera.jpg'),
        _p2,
      ]);
    });

    test('catégorie choisie : nom gardé pour l’affichage', () async {
      final c = await start();
      const services = ListingCategory(id: 'c2', name: 'Services');

      c.read(provider.notifier).setCategory(services);

      expect(c.read(provider).category, services);
      expect(c.read(provider).draft.categoryId, 'c2');
    });
  });

  group('Enregistrement', () {
    test('rien de changé : aucun appel', () async {
      final c = await start();

      await c.read(provider.notifier).save();

      expect(publisher.calls, isEmpty);
      expect(c.read(provider).saved, isFalse);
    });

    test('incomplet : problèmes signalés, aucun appel', () async {
      final c = await start();
      final controller = c.read(provider.notifier)..setTitle('a');

      await controller.save();

      expect(c.read(provider).visibleProblems, {DraftProblem.titleTooShort});
      expect(publisher.calls, isEmpty);
    });

    test('réussi : seuls les changements, puis « enregistrée »', () async {
      final c = await start();
      final controller = c.read(provider.notifier)
        ..setPrice('900')
        ..setNegotiable(value: false);
      final steps = <EditStep?>[];
      c.listen(provider, (_, next) => steps.add(next.step));

      await controller.save();

      expect(
        publisher.changes.single,
        const ListingChanges(price: 900, isNegotiable: false),
      );
      expect(steps, contains(EditStep.details));
      final state = c.read(provider);
      expect(state.saved, isTrue);
      expect(state.isSaving, isFalse);
      expect(state.hasChanges, isFalse);
    });

    test('échec avant tout changement : saisie gardée, message', () async {
      publisher.updated = const Err(NetworkFailure());
      final c = await start();
      final controller = c.read(provider.notifier)..setPrice('900');

      await controller.save();

      final state = c.read(provider);
      expect(state.failure, isA<NetworkFailure>());
      expect(state.partiallySaved, isFalse);
      expect(state.draft.price, 900);
      expect(listings.detailCalls, hasLength(1));

      controller.failureShown();
      expect(c.read(provider).failure, isNull);
    });

    test('échec après un changement : annonce relue, message dédié', () async {
      publisher.uploaded = const Err(TimeoutFailure());
      final c = await start();
      final controller = c.read(provider.notifier)..setPrice('900');
      await controller.takePhoto();
      listings.detail = Ok(_mine());

      await controller.save();

      final state = c.read(provider);
      expect(state.failure, isA<TimeoutFailure>());
      expect(state.partiallySaved, isTrue);
      expect(state.revision, 2);
      expect(state.isSaving, isFalse);
      expect(state.draft.localPhotos, isEmpty);
      expect(listings.detailCalls, hasLength(2));
    });

    test('échec, puis relecture impossible : saisie gardée, message', () async {
      publisher.uploaded = const Err(TimeoutFailure());
      final c = await start();
      final controller = c.read(provider.notifier)..setPrice('900');
      await controller.takePhoto();
      listings.detail = const Err(NetworkFailure());

      await controller.save();

      final state = c.read(provider);
      expect(state.phase, EditPhase.ready);
      expect(state.failure, isA<TimeoutFailure>());
      expect(state.isSaving, isFalse);
      expect(state.draft.localPhotos, hasLength(1));
      expect(listings.detailCalls, hasLength(2));
    });

    test('vendue entre-temps : écran « vendue »', () async {
      publisher.updated = const Err(
        ConflictFailure(code: ListingConflicts.sold),
      );
      final c = await start();
      final controller = c.read(provider.notifier)..setPrice('900');

      await controller.save();

      expect(c.read(provider).phase, EditPhase.sold);
    });
  });
}
