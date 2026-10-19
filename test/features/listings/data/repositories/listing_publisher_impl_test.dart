import 'dart:io';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/data/repositories/listing_publisher_impl.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http_server.dart';

const _draft = ListingDraft(
  photos: [LocalPhoto('/p/1.jpg')],
  title: '  Vélo de ville  ',
  price: 900,
  categoryId: 'c1',
  district: 'maarif',
  condition: ListingCondition.likeNew,
  description: ' Freins neufs, pneus en bon état. ',
  isNegotiable: true,
  deliveryMode: DeliveryMode.both,
);

void main() {
  late FakeHttpServer server;
  late ListingPublisherImpl publisher;

  setUp(() {
    server = FakeHttpServer();
    publisher = ListingPublisherImpl(server.client());
  });

  group('Création (masquée)', () {
    test('POST /api/listings : textes nettoyés, valeurs du serveur', () async {
      server.respond([
        (
          201,
          {
            'listing': {'id': 'abc123'},
          },
        ),
      ]);

      final result = await publisher.createHidden(_draft);

      expect((result as Ok<String>).value, 'abc123');
      final request = server.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/listings');
      expect(request.data, {
        'title': 'Vélo de ville',
        'description': 'Freins neufs, pneus en bon état.',
        'price': 900,
        'categoryId': 'c1',
        'city': 'casablanca',
        'district': 'maarif',
        'condition': 'LIKE_NEW',
        'isNegotiable': true,
        'deliveryMode': 'BOTH',
        'status': 'INACTIVE',
      });
    });

    test('identifiant invalide dans la réponse : UnexpectedFailure', () async {
      server.respond([
        (
          201,
          {
            'listing': {'id': '../admin'},
          },
        ),
      ]);

      final result = await publisher.createHidden(_draft);

      expect((result as Err).failure, isA<UnexpectedFailure>());
    });

    test('trop d’annonces (429) : RateLimitFailure', () async {
      server.respond([
        (429, {'error': 'x'}),
      ]);

      final result = await publisher.createHidden(_draft);

      expect((result as Err).failure, isA<RateLimitFailure>());
    });
  });

  group('Photos', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('afrimarket-photos');
      addTearDown(() async {
        try {
          await dir.delete(recursive: true);
        } on FileSystemException {
          // Windows : le faux serveur ne lit pas les fichiers, qui restent
          // ouverts jusqu'à la fin du test. Le dossier temporaire sera
          // nettoyé par le système.
        }
      });
    });

    test('multipart « images », noms neutres, dans l’ordre', () async {
      final jpg = File('${dir.path}/IMG_2026_maison.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      final png = File('${dir.path}/capture.PNG')..writeAsBytesSync([4, 5]);
      server.respond([(201, <String, dynamic>{})]);

      final result = await publisher.uploadPhotos('abc123', [
        LocalPhoto(jpg.path),
        LocalPhoto(png.path),
      ]);

      expect(result, isA<Ok<void>>());
      final request = server.requests.single;
      expect(request.path, '/api/listings/abc123/images');
      expect(request.sendTimeout, ListingPublisherImpl.uploadTimeout);
      final form = request.data as FormData;
      expect(form.files.map((entry) => entry.key), ['images', 'images']);
      expect(form.files.map((entry) => entry.value.filename), [
        'photo-1.jpg',
        'photo-2.png',
      ]);
      expect(form.files.map((entry) => entry.value.contentType?.mimeType), [
        'image/jpeg',
        'image/png',
      ]);
    });

    test('fichier introuvable : échec, sans plantage', () async {
      final result = await publisher.uploadPhotos('abc123', [
        LocalPhoto('${dir.path}/absente.jpg'),
      ]);

      expect(result, isA<Err<void>>());
      expect(server.requests, isEmpty);
    });
  });

  test('mise en ligne : PUT status ACTIVE', () async {
    final result = await publisher.publish('abc123');

    expect(result, isA<Ok<void>>());
    final request = server.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, '/api/listings/abc123');
    expect(request.data, {'status': 'ACTIVE'});
  });

  test('suppression : DELETE', () async {
    final result = await publisher.delete('abc123');

    expect(result, isA<Ok<void>>());
    expect(server.requests.single.method, 'DELETE');
    expect(server.requests.single.path, '/api/listings/abc123');
  });
}
