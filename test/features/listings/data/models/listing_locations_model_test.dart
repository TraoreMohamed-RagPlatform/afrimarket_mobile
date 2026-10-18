import 'package:afrimarket_mobile/features/listings/data/models/listing_locations_model.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final locations = ListingLocationsModel.fromJson({
    'data': {
      'locations': [
        {
          'slug': 'casablanca',
          'name': 'Casablanca',
          'districts': [
            {'slug': 'maarif', 'name': 'Maârif'},
            {'slug': 'Bad Slug', 'name': 'Ignoré'},
            {'slug': 'anfa', 'name': ' '},
            'texte',
          ],
        },
        {'slug': '../x', 'name': 'Ignorée'},
        'texte',
      ],
    },
  });

  test('quartier et ville', () {
    expect(
      locations.label(city: 'casablanca', district: 'maarif'),
      'Maârif, Casablanca',
    );
  });

  test('quartier inconnu ou absent : la ville seule', () {
    expect(locations.label(city: 'casablanca', district: 'anfa'), 'Casablanca');
    expect(locations.label(city: 'casablanca'), 'Casablanca');
  });

  test('ville inconnue : rien (jamais l’identifiant brut)', () {
    expect(locations.label(city: 'rabat', district: 'agdal'), isNull);
    expect(locations.label(city: '../x'), isNull);
    expect(locations.label(), isNull);
  });

  test('liste absente : vide', () {
    expect(
      ListingLocationsModel.fromJson(<String, dynamic>{}),
      ListingLocations.empty,
    );
    expect(
      ListingLocationsModel.fromJson({
        'data': {'locations': 'non'},
      }),
      ListingLocations.empty,
    );
  });
}
