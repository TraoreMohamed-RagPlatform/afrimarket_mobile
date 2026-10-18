import 'package:afrimarket_mobile/features/listings/data/models/listing_page_model.dart';
import 'package:flutter_test/flutter_test.dart';

final Uri _base = Uri.parse('https://api.example.com');

Map<String, dynamic> _listing({
  Object? id = 'cm1abc',
  Object? title = 'Canapé 3 places',
  Object? price = 1200,
  Object? createdAt = '2026-10-18T08:00:00.000Z',
  Object? images,
  Object? isSold,
}) => {
  'id': id,
  'title': title,
  'price': price,
  'createdAt': createdAt,
  'images': ?images,
  'isSold': ?isSold,
};

Map<String, dynamic> _response(
  List<Object?> listings, {
  Object? page = 1,
  Object? pages = 1,
}) => {
  'listings': listings,
  'pagination': {'page': page, 'limit': 20, 'total': 0, 'pages': pages},
};

void main() {
  group('Réponse valide', () {
    test('convertit une annonce', () {
      final page = ListingPageModel.fromJson(
        _response([
          _listing(
            images: [
              {'url': 'https://cdn.example.com/a.jpg'},
            ],
            isSold: true,
          ),
        ]),
        baseUrl: _base,
      );

      final item = page.items.single;
      expect(item.id, 'cm1abc');
      expect(item.title, 'Canapé 3 places');
      expect(item.price, 1200);
      expect(item.createdAt, DateTime.utc(2026, 10, 18, 8));
      expect(item.imageUrl, 'https://cdn.example.com/a.jpg');
      expect(item.isSold, isTrue);
    });

    test('prix décimal et gratuit (0) acceptés', () {
      final page = ListingPageModel.fromJson(
        _response([_listing(price: 99.5), _listing(id: 'b', price: 0)]),
        baseUrl: _base,
      );

      expect(page.items.map((item) => item.price), [99.5, 0]);
    });

    test('titre nettoyé des espaces autour', () {
      final page = ListingPageModel.fromJson(
        _response([_listing(title: '  Lit 1 place  ')]),
        baseUrl: _base,
      );

      expect(page.items.single.title, 'Lit 1 place');
    });

    test('page suivante : hasMore tant que page < pages', () {
      expect(
        ListingPageModel.fromJson(
          _response([], pages: 3),
          baseUrl: _base,
        ).hasMore,
        isTrue,
      );
      expect(
        ListingPageModel.fromJson(
          _response([], page: 3, pages: 3),
          baseUrl: _base,
        ).hasMore,
        isFalse,
      );
      expect(
        ListingPageModel.fromJson(
          _response([], pages: 0),
          baseUrl: _base,
        ).hasMore,
        isFalse,
      );
    });

    test('numéros de page en texte acceptés', () {
      final page = ListingPageModel.fromJson(
        _response([], page: '2', pages: '5'),
        baseUrl: _base,
      );

      expect(page.page, 2);
      expect(page.hasMore, isTrue);
    });
  });

  group('Photos', () {
    String? imageOf(Object? images) => ListingPageModel.fromJson(
      _response([_listing(images: images)]),
      baseUrl: _base,
    ).items.single.imageUrl;

    test('adresse relative complétée avec le serveur', () {
      expect(
        imageOf([
          {'url': '/uploads/listings/a.jpg'},
        ]),
        'https://api.example.com/uploads/listings/a.jpg',
      );
    });

    test('première photo valide retenue', () {
      expect(
        imageOf([
          {'url': ''},
          {'url': 42},
          'pas une photo',
          {'url': 'https://cdn.example.com/2.jpg'},
        ]),
        'https://cdn.example.com/2.jpg',
      );
    });

    test('schéma dangereux refusé (sécurité)', () {
      expect(
        imageOf([
          {'url': 'javascript:alert(1)'},
          {'url': 'file:///etc/passwd'},
        ]),
        isNull,
      );
    });

    test('sans photo : null', () {
      expect(imageOf(null), isNull);
      expect(imageOf(<Object>[]), isNull);
      expect(imageOf('pas une liste'), isNull);
    });
  });

  group('Annonces mal formées : ignorées, le reste du fil s’affiche', () {
    for (final (name, bad) in [
      ('identifiant absent', _listing(id: null)),
      ('identifiant vide', _listing(id: '')),
      ('identifiant dangereux', _listing(id: '../admin')),
      ('identifiant trop long', _listing(id: 'x' * 65)),
      ('titre vide', _listing(title: '   ')),
      ('titre non texte', _listing(title: 12)),
      ('prix négatif', _listing(price: -1)),
      ('prix non numérique', _listing(price: '1200')),
      ('prix infini', _listing(price: double.infinity)),
      ('date invalide', _listing(createdAt: 'hier')),
      ('date absente', _listing(createdAt: null)),
    ]) {
      test(name, () {
        final page = ListingPageModel.fromJson(
          _response([bad, _listing(id: 'ok')]),
          baseUrl: _base,
        );

        expect(page.items.map((item) => item.id), ['ok']);
      });
    }

    test('élément qui n’est pas un objet', () {
      final page = ListingPageModel.fromJson(
        _response(['texte', null, _listing(id: 'ok')]),
        baseUrl: _base,
      );

      expect(page.items.map((item) => item.id), ['ok']);
    });
  });

  group('Réponse mal formée : FormatException', () {
    test('liste absente', () {
      expect(
        () => ListingPageModel.fromJson({
          'pagination': <String, dynamic>{},
        }, baseUrl: _base),
        throwsFormatException,
      );
    });

    test('pagination absente', () {
      expect(
        () =>
            ListingPageModel.fromJson({'listings': <Object>[]}, baseUrl: _base),
        throwsFormatException,
      );
    });
  });
}
