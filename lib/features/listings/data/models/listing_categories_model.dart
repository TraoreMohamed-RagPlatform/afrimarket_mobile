import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';

/// DTO : catégories de la réponse `GET /api/filters`.
///
/// ```json
/// { "data": { "categories": [ { "id", "name" } ], ... } }
/// ```
///
/// Une réponse sans liste de catégories lève une [FormatException] ; une
/// catégorie mal formée est ignorée.
abstract final class ListingCategoriesModel {
  static List<ListingCategory> fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final categories = data is Map<String, dynamic> ? data['categories'] : null;
    if (categories is! List) {
      throw const FormatException('Catégories manquantes');
    }

    return [
      for (final category in categories)
        if (category is Map<String, dynamic>) ?_category(category),
    ];
  }

  static ListingCategory? _category(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || name.trim().isEmpty) return null;
    return ListingCategory(id: id, name: name.trim());
  }
}
