import 'package:meta/meta.dart';

/// Catégorie d'annonces (Logement, Articles, Services...), telle que
/// définie par le serveur.
@immutable
final class ListingCategory {
  const new({required this.id, required this.name, this.slug, this.icon});

  final String id;

  /// Nom fourni par le serveur : à afficher via `userText()`.
  final String name;

  /// Identifiant lisible (« logement »), s'il est connu.
  final String? slug;

  /// Nom de l'icône Phosphor proposée par le serveur (« house »).
  final String? icon;

  @override
  bool operator ==(Object other) =>
      other is ListingCategory &&
      other.id == id &&
      other.name == name &&
      other.slug == slug &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(id, name, slug, icon);
}
