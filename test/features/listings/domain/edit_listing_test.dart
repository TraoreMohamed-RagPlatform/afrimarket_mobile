import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_changes.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/edit_listing_usecase.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/manage_own_listing_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_listings_repository.dart';
import '../../../helpers/fake_publish.dart';

RemotePhoto _remote(String id) =>
    RemotePhoto(id: id, url: 'https://api.example.com/$id.jpg');

/// Annonce en ligne : 3 photos (p1 principale).
final _online = ListingDraft(
  photos: [_remote('p1'), _remote('p2'), _remote('p3')],
  title: 'Canapé',
  price: 1000,
  categoryId: 'c1',
  district: 'maarif',
  condition: ListingCondition.good,
  description: 'Très bon état, à récupérer.',
);

void main() {
  group('ListingDraft.fromDetail', () {
    test('annonce en ligne → saisie de départ', () {
      final detail = sampleDetail(
        photos: [_remote('p1')],
        category: const ListingCategory(id: 'c1', name: 'Mobilier'),
      );

      final draft = ListingDraft.fromDetail(detail);

      expect(draft.photos, [_remote('p1')]);
      expect(draft.title, detail.title);
      expect(draft.price, 1200);
      expect(draft.categoryId, 'c1');
      expect(draft.city, 'casablanca');
      expect(draft.district, 'maarif');
      expect(draft.condition, ListingCondition.good);
      expect(draft.isNegotiable, isTrue);
      expect(draft.isReady, isTrue);
      expect(draft.localPhotos, isEmpty);
    });
  });

  group('ListingChanges.between', () {
    test('rien de changé (espaces autour ignorés)', () {
      final same = _online.copyWith(title: '  Canapé ');

      expect(ListingChanges.between(_online, same).isEmpty, isTrue);
    });

    test('seuls les champs modifiés, textes nettoyés', () {
      final edited = _online.copyWith(
        title: ' Canapé gris ',
        price: () => 800,
        isNegotiable: true,
        deliveryMode: DeliveryMode.both,
      );

      expect(
        ListingChanges.between(_online, edited),
        const ListingChanges(
          title: 'Canapé gris',
          price: 800,
          isNegotiable: true,
          deliveryMode: DeliveryMode.both,
        ),
      );
    });
  });

  group('EditListingUseCase', () {
    late FakeListingPublisher publisher;
    late List<EditStep> steps;
    late int applied;

    setUp(() {
      publisher = FakeListingPublisher();
      steps = [];
      applied = 0;
    });

    Future<Result<void>> save(ListingDraft edited) =>
        EditListingUseCase(publisher)(
          listingId: 'l1',
          original: _online,
          edited: edited,
          onStep: steps.add,
          onApplied: () => applied++,
        );

    test('saisie incomplète : refusée sans appel', () async {
      final result = await save(_online.copyWith(title: 'a'));

      expect((result as Err).failure, isA<ValidationFailure>());
      expect(publisher.calls, isEmpty);
    });

    test('aucun changement : aucun appel', () async {
      expect((await save(_online)).isOk, isTrue);
      expect(publisher.calls, isEmpty);
      expect(steps, isEmpty);
    });

    test('champs seulement : un seul appel', () async {
      final result = await save(_online.copyWith(price: () => 900));

      expect(result.isOk, isTrue);
      expect(publisher.calls, ['update:l1']);
      expect(publisher.changes.single, const ListingChanges(price: 900));
      expect(steps, [EditStep.details]);
      expect(applied, 1);
    });

    test('photo principale changée : nouvel ordre seulement', () async {
      final edited = _online.copyWith(
        photos: [_remote('p3'), _remote('p1'), _remote('p2')],
      );

      await save(edited);

      expect(publisher.calls, ['reorder:p3,p1,p2']);
      expect(steps, [EditStep.photos]);
    });

    test('retrait et ajout : retrait, envoi, puis ordre voulu', () async {
      final edited = _online.copyWith(
        photos: [const LocalPhoto('/n.jpg'), _remote('p1'), _remote('p3')],
      );

      await save(edited);

      expect(publisher.calls, [
        'deletePhoto:p2',
        'upload:l1:1',
        'reorder:up-1,p1,p3',
      ]);
    });

    test('ajout à la fin : pas de nouvel ordre', () async {
      final edited = _online.copyWith(
        photos: [..._online.photos, const LocalPhoto('/n.jpg')],
      );

      await save(edited);

      expect(publisher.calls, ['upload:l1:1']);
    });

    test(
      'toutes remplacées : une ancienne reste jusqu’aux nouvelles',
      () async {
        final edited = _online.copyWith(
          photos: [const LocalPhoto('/a.jpg'), const LocalPhoto('/b.jpg')],
        );

        await save(edited);

        expect(publisher.calls, [
          'deletePhoto:p2',
          'deletePhoto:p3',
          'upload:l1:2',
          'deletePhoto:p1',
        ]);
      },
    );

    test('10 photos remplacées par 10 nouvelles : jamais plus de 10', () async {
      final ten = [for (var i = 0; i < 10; i++) _remote('o$i')];
      final fresh = [for (var i = 0; i < 10; i++) LocalPhoto('/n$i.jpg')];
      final original = _online.copyWith(photos: ten);

      await EditListingUseCase(publisher)(
        listingId: 'l1',
        original: original,
        edited: original.copyWith(photos: fresh),
      );

      expect(publisher.calls.where((c) => c.startsWith('upload')), [
        'upload:l1:9',
        'upload:l1:1',
      ]);
      expect(publisher.calls.indexOf('deletePhoto:o0'), 10);
      expect(publisher.calls.last, 'upload:l1:1');
    });

    test('échec des champs : rien d’autre, rien d’enregistré', () async {
      publisher.updated = const Err(NetworkFailure());

      final result = await save(
        _online.copyWith(title: 'Canapé gris', photos: [_remote('p1')]),
      );

      expect((result as Err).failure, isA<NetworkFailure>());
      expect(publisher.calls, ['update:l1']);
      expect(applied, 0);
    });

    test(
      'échec des photos après les champs : déjà en partie enregistrée',
      () async {
        publisher.uploaded = const Err(TimeoutFailure());

        final result = await save(
          _online.copyWith(
            title: 'Canapé gris',
            photos: [..._online.photos, const LocalPhoto('/n.jpg')],
          ),
        );

        expect((result as Err).failure, isA<TimeoutFailure>());
        expect(applied, 1);
      },
    );

    test('retrait refusé : échec', () async {
      publisher.photoDeleted = const Err(ConflictFailure(code: 'LAST_PHOTO'));

      final result = await save(_online.copyWith(photos: [_remote('p1')]));

      expect((result as Err).failure, isA<ConflictFailure>());
    });

    test('ordre refusé : échec', () async {
      publisher.reordered = const Err(ServerFailure());

      final result = await save(
        _online.copyWith(photos: [_remote('p2'), _remote('p1'), _remote('p3')]),
      );

      expect((result as Err).failure, isA<ServerFailure>());
    });

    test('réponse d’envoi incomplète : échec inattendu', () async {
      publisher.uploaded = const Ok([]);

      final result = await save(
        _online.copyWith(
          photos: [..._online.photos, const LocalPhoto('/n.jpg')],
        ),
      );

      expect((result as Err).failure, isA<UnexpectedFailure>());
    });

    test('retrait refusé pendant le remplacement complet : échec', () async {
      final failing = _FailingDelete();

      final result = await EditListingUseCase(failing)(
        listingId: 'l1',
        original: _online.copyWith(photos: [_remote('p1')]),
        edited: _online.copyWith(photos: [const LocalPhoto('/a.jpg')]),
      );

      expect((result as Err).failure, isA<NetworkFailure>());
      expect(failing.calls, ['upload:l1:1']);
      expect(failing.deletes, 1);
    });
  });

  test('ManageOwnListingUseCase.delete : suppression demandée', () async {
    final publisher = FakeListingPublisher();

    await ManageOwnListingUseCase(publisher).delete('l1');

    expect(publisher.calls, ['delete:l1']);
  });
}

/// Tout retrait de photo est refusé.
class _FailingDelete extends FakeListingPublisher {
  int deletes = 0;

  @override
  Future<Result<void>> deletePhoto(String listingId, String photoId) async {
    deletes++;
    return const Err(NetworkFailure());
  }
}
