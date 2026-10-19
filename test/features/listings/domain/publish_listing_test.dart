import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/publish_listing_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_publish.dart';

/// Annonce complète : « Vélo de ville », 900 DH, Maârif, bon état.
const _ready = ListingDraft(
  photos: [LocalPhoto('/p/1.jpg'), LocalPhoto('/p/2.jpg')],
  title: 'Vélo de ville',
  price: 900,
  categoryId: 'c1',
  district: 'maarif',
  condition: ListingCondition.good,
  description: 'Freins neufs, pneus en bon état.',
);

void main() {
  group('ListingDraft', () {
    test('vide : tout est à compléter', () {
      expect(ListingDraft.empty.isEmpty, isTrue);
      expect(ListingDraft.empty.problems, {
        DraftProblem.noPhoto,
        DraftProblem.titleTooShort,
        DraftProblem.noPrice,
        DraftProblem.noCategory,
        DraftProblem.noDistrict,
        DraftProblem.noCondition,
        DraftProblem.descriptionTooShort,
      });
    });

    test('complète : prête à publier', () {
      expect(_ready.isReady, isTrue);
      expect(_ready.isEmpty, isFalse);
    });

    test('gratuit (0 DH) accepté ; prix démesuré refusé', () {
      expect(_ready.copyWith(price: () => 0).isReady, isTrue);
      expect(_ready.copyWith(price: () => ListingDraft.maxPrice + 1).problems, {
        DraftProblem.priceTooHigh,
      });
    });

    test('espaces seuls : titre et description trop courts', () {
      expect(
        _ready.copyWith(title: '   ab  ', description: '          ').problems,
        {DraftProblem.titleTooShort, DraftProblem.descriptionTooShort},
      );
    });

    test('prix effacé', () {
      expect(_ready.copyWith(price: () => null).problems, {
        DraftProblem.noPrice,
      });
    });

    test('égalité par valeur (photos comprises)', () {
      expect(_ready.copyWith(), _ready);
      expect(_ready.copyWith().hashCode, _ready.hashCode);
      expect(
        _ready.copyWith(photos: [const LocalPhoto('/p/1.jpg')]),
        isNot(_ready),
      );
    });
  });

  group('PublishListingUseCase', () {
    late FakeListingPublisher publisher;
    late List<PublishStep> steps;

    Future<Result<String>> publish([ListingDraft draft = _ready]) =>
        PublishListingUseCase(publisher)(draft, onStep: steps.add);

    setUp(() {
      publisher = FakeListingPublisher();
      steps = [];
    });

    test('créée masquée, photos envoyées dans l’ordre, puis publiée', () async {
      final result = await publish();

      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, 'new-1');
      expect(publisher.calls, ['create', 'upload:new-1:2', 'publish:new-1']);
      expect(publisher.uploadedPhotos.single, _ready.photos);
      expect(steps, PublishStep.values);
    });

    test('incomplète : refusée sans aucun appel', () async {
      final result = await publish(_ready.copyWith(photos: const []));

      expect((result as Err).failure, isA<ValidationFailure>());
      expect(publisher.calls, isEmpty);
      expect(steps, isEmpty);
    });

    test('création refusée : rien d’autre n’est tenté', () async {
      publisher.created = const Err(RateLimitFailure());

      final result = await publish();

      expect((result as Err).failure, isA<RateLimitFailure>());
      expect(publisher.calls, ['create']);
    });

    test('photos refusées : l’annonce masquée est supprimée', () async {
      publisher.uploaded = const Err(NetworkFailure());

      final result = await publish();

      expect((result as Err).failure, isA<NetworkFailure>());
      expect(publisher.calls, ['create', 'upload:new-1:2', 'delete:new-1']);
    });

    test('mise en ligne refusée : l’annonce masquée est supprimée', () async {
      publisher.published = const Err(ServerFailure(statusCode: 500));

      final result = await publish();

      expect((result as Err).failure, isA<ServerFailure>());
      expect(publisher.calls.last, 'delete:new-1');
    });

    test('suppression ratée : l’erreur d’origine est renvoyée', () async {
      publisher
        ..uploaded = const Err(TimeoutFailure())
        ..deleted = const Err(NetworkFailure());

      final result = await publish();

      expect((result as Err).failure, isA<TimeoutFailure>());
    });
  });
}
