import 'package:meta/meta.dart';

/// Annonce telle qu'elle apparaît dans le fil : le résumé d'une carte.
///
/// Entité métier : Dart pur, sans dépendance à Flutter ni à l'API.
@immutable
final class ListingSummary {
  const new({
    required this.id,
    required this.title,
    required this.price,
    required this.createdAt,
    this.imageUrl,
    this.isSold = false,
  });

  /// Durée pendant laquelle une annonce est « Récente » (badge ambre).
  static const recentWindow = Duration(hours: 24);

  final String id;

  /// Titre saisi par le vendeur : à afficher via `userText()`.
  final String title;

  /// Prix en dirhams (0 = gratuit).
  final num price;

  final DateTime createdAt;

  /// Adresse web (http ou https) de la première photo, si elle existe.
  final String? imageUrl;

  final bool isSold;

  /// Vrai si l'annonce a été publiée il y a moins de [recentWindow].
  ///
  /// Une date dans le futur (horloge du téléphone en retard) n'est pas
  /// considérée comme récente.
  bool isRecentAt(DateTime now) {
    final age = now.difference(createdAt);
    return !age.isNegative && age < recentWindow;
  }

  @override
  bool operator ==(Object other) =>
      other is ListingSummary &&
      other.id == id &&
      other.title == title &&
      other.price == price &&
      other.createdAt == createdAt &&
      other.imageUrl == imageUrl &&
      other.isSold == isSold;

  @override
  int get hashCode =>
      Object.hash(id, title, price, createdAt, imageUrl, isSold);
}
