import 'package:afrimarket_mobile/features/listings/data/models/listing_categories_model.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('convertit les catégories, dans l’ordre du serveur', () {
    final categories = ListingCategoriesModel.fromJson({
      'data': {
        'categories': [
          {'id': 'c1', 'name': 'Logement'},
          {'id': 'c2', 'name': ' Services '},
        ],
      },
    });

    expect(categories, const [
      ListingCategory(id: 'c1', name: 'Logement'),
      ListingCategory(id: 'c2', name: 'Services'),
    ]);
  });

  test('catégorie mal formée ignorée', () {
    final categories = ListingCategoriesModel.fromJson({
      'data': {
        'categories': [
          {'id': '', 'name': 'Sans id'},
          {'id': 'c1', 'name': '  '},
          {'id': 3, 'name': 'Id numérique'},
          'texte',
          {'id': 'c2', 'name': 'Emploi'},
        ],
      },
    });

    expect(categories, const [ListingCategory(id: 'c2', name: 'Emploi')]);
  });

  test('liste absente : FormatException', () {
    expect(
      () => ListingCategoriesModel.fromJson({'data': <String, dynamic>{}}),
      throwsFormatException,
    );
    expect(
      () => ListingCategoriesModel.fromJson(<String, dynamic>{}),
      throwsFormatException,
    );
  });
}
