import 'package:meta/meta.dart';

/// Catégorie d'annonces (Logement, Articles, Services...), telle que
/// définie par le serveur.
@immutable
final class ListingCategory {
  const new({required this.id, required this.name});

  final String id;

  /// Nom fourni par le serveur : à afficher via `userText()`.
  final String name;

  @override
  bool operator ==(Object other) =>
      other is ListingCategory && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
