import 'package:afrimarket_mobile/features/listings/data/models/listing_json.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';

/// DTO : villes et quartiers dans la réponse de `GET /api/filters`.
///
/// ```json
/// { "data": { "locations": [ { "slug": "casablanca", "name": "Casablanca",
///   "districts": [ { "slug": "maarif", "name": "Maârif" } ] } ] } }
/// ```
///
/// Entrée mal formée → ignorée ; liste absente → liste vide (le lieu
/// n'est simplement pas affiché).
abstract final class ListingLocationsModel {
  static final RegExp _slug = RegExp(r'^[a-z0-9-]{1,40}$');

  static ListingLocations fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final locations = data is Map<String, dynamic> ? data['locations'] : null;
    if (locations is! List) return ListingLocations.empty;

    final cities = <String, ({String name, Map<String, String> districts})>{};
    for (final city in locations) {
      if (city is! Map<String, dynamic>) continue;
      final slug = _validSlug(city['slug']);
      final name = ListingJson.nonEmptyText(city['name']);
      if (slug == null || name == null) continue;

      final districts = <String, String>{};
      final rawDistricts = city['districts'];
      if (rawDistricts is List) {
        for (final district in rawDistricts) {
          if (district is! Map<String, dynamic>) continue;
          final districtSlug = _validSlug(district['slug']);
          final districtName = ListingJson.nonEmptyText(district['name']);
          if (districtSlug != null && districtName != null) {
            districts[districtSlug] = districtName;
          }
        }
      }
      cities[slug] = (name: name, districts: districts);
    }
    return ListingLocations(cities);
  }

  static String? _validSlug(Object? value) =>
      value is String && _slug.hasMatch(value) ? value : null;
}
