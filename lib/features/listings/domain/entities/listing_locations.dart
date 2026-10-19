import 'package:afrimarket_mobile/core/text/text_fold.dart';
import 'package:meta/meta.dart';

/// Villes et quartiers proposés par le serveur (liste fixe).
///
/// Les annonces n'enregistrent que des identifiants (« maarif ») ; cette
/// liste donne les noms à afficher (« Maârif »).
@immutable
final class ListingLocations {
  const new(this._cities);

  /// Aucune ville connue (liste pas encore chargée, ou indisponible).
  static const empty = ListingLocations({});

  /// Identifiant de ville → (nom de la ville, quartiers : identifiant → nom).
  final Map<String, ({String name, Map<String, String> districts})> _cities;

  /// « Maârif, Casablanca », « Casablanca », ou null si rien n'est connu.
  ///
  /// Un identifiant inconnu n'est jamais affiché tel quel.
  String? label({String? city, String? district}) {
    final known = city == null ? null : _cities[city];
    if (known == null) return null;
    final districtName = district == null ? null : known.districts[district];
    return districtName == null ? known.name : '$districtName, ${known.name}';
  }

  /// Identifiants des villes connues.
  Iterable<String> get cities => _cities.keys;

  /// Nom d'une ville, ou null si elle est inconnue.
  String? cityName(String city) => _cities[city]?.name;

  /// Quartiers d'une ville, triés par nom sans tenir compte des accents ni
  /// des majuscules (« Aïn Chock » avant « Anfa ») : (identifiant, nom).
  List<({String slug, String name})> districtsOf(String city) {
    final districts = _cities[city]?.districts ?? const <String, String>{};
    return [
      for (final entry in districts.entries)
        (slug: entry.key, name: entry.value),
    ]..sort((a, b) => compareFolded(a.name, b.name));
  }

  @override
  bool operator ==(Object other) =>
      other is ListingLocations && _sameCities(other._cities, _cities);

  @override
  int get hashCode => Object.hashAllUnordered(_cities.keys);
}

bool _sameCities(
  Map<String, ({String name, Map<String, String> districts})> a,
  Map<String, ({String name, Map<String, String> districts})> b,
) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final other = b[entry.key];
    if (other == null || other.name != entry.value.name) return false;
    final districts = entry.value.districts;
    if (other.districts.length != districts.length) return false;
    for (final district in districts.entries) {
      if (other.districts[district.key] != district.value) return false;
    }
  }
  return true;
}
