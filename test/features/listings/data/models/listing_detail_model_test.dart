import 'package:afrimarket_mobile/features/listings/data/models/listing_detail_model.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:flutter_test/flutter_test.dart';

final Uri _base = Uri.parse('https://api.example.com');

Map<String, dynamic> _seller([Map<String, dynamic> extra = const {}]) => {
  'id': 'seller-1',
  'username': 'aminata',
  'fullName': 'Aminata K.',
  'avatar': null,
  'avgRating': 4.8,
  'totalRatings': 12,
  'isIdentityVerified': true,
  'createdAt': '2025-03-01T00:00:00.000Z',
  'responseTimeMinutes': 45,
  'canCall': true,
  'canWhatsapp': true,
  ...extra,
};

Map<String, dynamic> _listing([Map<String, dynamic> extra = const {}]) => {
  'id': 'listing-1',
  'title': '  Canapé 3 places  ',
  'description': ' Très bon état. ',
  'price': 1200,
  'previousPrice': 1500,
  'isNegotiable': true,
  'isSold': false,
  'status': 'ACTIVE',
  'condition': 'GOOD',
  'city': 'casablanca',
  'district': 'maarif',
  'deliveryMode': 'BOTH',
  'createdAt': '2026-10-18T08:00:00.000Z',
  'category': {'id': 'c1', 'name': 'Mobilier'},
  'images': [
    {'url': '/uploads/listings/a.jpg'},
    {'url': 'javascript:alert(1)'},
    {'url': 'https://cdn.example.com/b.jpg'},
  ],
  'user': _seller(),
  ...extra,
};

ListingDetail _parse([Map<String, dynamic> extra = const {}]) =>
    ListingDetailModel.fromJson({'listing': _listing(extra)}, baseUrl: _base);

void main() {
  test('convertit une annonce complète', () {
    final listing = _parse();

    expect(listing.id, 'listing-1');
    expect(listing.title, 'Canapé 3 places');
    expect(listing.description, 'Très bon état.');
    expect(listing.price, 1200);
    expect(listing.previousPrice, 1500);
    expect(listing.isNegotiable, isTrue);
    expect(listing.condition, ListingCondition.good);
    expect(listing.categoryName, 'Mobilier');
    expect(listing.city, 'casablanca');
    expect(listing.district, 'maarif');
    expect(listing.deliveryMode, DeliveryMode.both);
    expect(listing.createdAt, DateTime.utc(2026, 10, 18, 8));
    // Adresse relative complétée, adresse dangereuse ignorée.
    expect(listing.imageUrls, [
      'https://api.example.com/uploads/listings/a.jpg',
      'https://cdn.example.com/b.jpg',
    ]);
  });

  test('vendeur : nom complet, note, ancienneté, temps de réponse', () {
    final seller = _parse().seller;

    expect(seller.id, 'seller-1');
    expect(seller.name, 'Aminata K.');
    expect(seller.averageRating, 4.8);
    expect(seller.ratingCount, 12);
    expect(seller.isIdentityVerified, isTrue);
    expect(seller.memberSince, DateTime.utc(2025, 3));
    expect(seller.responseTimeMinutes, 45);
    expect(seller.canCall, isTrue);
    expect(seller.canWhatsapp, isTrue);
  });

  test('sans nom complet : le pseudo', () {
    final seller = _parse({
      'user': _seller({'fullName': '  '}),
    }).seller;

    expect(seller.name, 'aminata');
  });

  test('WhatsApp jamais sans appel possible', () {
    final seller = _parse({
      'user': _seller({'canCall': false, 'canWhatsapp': true}),
    }).seller;

    expect(seller.canCall, isFalse);
    expect(seller.canWhatsapp, isFalse);
  });

  test('vendue : par isSold ou par le statut', () {
    expect(_parse({'isSold': true}).isSold, isTrue);
    expect(_parse({'status': 'SOLD'}).isSold, isTrue);
  });

  group('Valeurs facultatives invalides : ignorées', () {
    test('ancien prix inférieur ou égal au prix', () {
      expect(_parse({'previousPrice': 1000}).previousPrice, isNull);
      expect(_parse({'previousPrice': 1200}).previousPrice, isNull);
      expect(_parse({'previousPrice': 'cher'}).previousPrice, isNull);
    });

    test('état, remise, lieu inconnus', () {
      final listing = _parse({
        'condition': 'BROKEN',
        'deliveryMode': 'DRONE',
        'city': '../etc',
        'district': 'Maârif',
      });

      expect(listing.condition, isNull);
      expect(listing.deliveryMode, DeliveryMode.pickup);
      expect(listing.city, isNull);
      expect(listing.district, isNull);
    });

    test('note hors limites, temps de réponse absurde', () {
      final seller = _parse({
        'user': _seller({
          'avgRating': 12,
          'totalRatings': -3,
          'responseTimeMinutes': 999999999,
        }),
      }).seller;

      expect(seller.averageRating, 5);
      expect(seller.ratingCount, 0);
      expect(seller.responseTimeMinutes, isNull);
    });

    test('description absente : texte vide', () {
      expect(_parse({'description': null}).description, '');
    });
  });

  group('Champ indispensable invalide : FormatException', () {
    for (final (name, extra) in <(String, Map<String, dynamic>)>[
      ('identifiant dangereux', {'id': '../admin'}),
      ('titre vide', {'title': '  '}),
      ('prix négatif', {'price': -1}),
      ('date invalide', {'createdAt': 'hier'}),
      ('vendeur absent', {'user': null}),
      (
        'vendeur sans identifiant',
        {
          'user': _seller({'id': null}),
        },
      ),
    ]) {
      test(name, () {
        expect(() => _parse(extra), throwsFormatException);
      });
    }

    test('annonce absente', () {
      expect(
        () => ListingDetailModel.fromJson(<String, dynamic>{}, baseUrl: _base),
        throwsFormatException,
      );
    });
  });
}
