import 'package:afrimarket_mobile/features/listings/domain/entities/listing_category.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_photo.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_seller.dart';
import 'package:meta/meta.dart';

/// État de l'article, tel que choisi par le vendeur.
enum ListingCondition { brandNew, likeNew, good, fair, poor }

/// Remise de l'article : en main propre, livraison, ou les deux.
enum DeliveryMode { pickup, delivery, both }

/// Annonce complète (page de détail).
///
/// Entité métier : Dart pur, sans dépendance à Flutter ni à l'API.
@immutable
final class ListingDetail {
  const new({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.createdAt,
    required this.seller,
    this.previousPrice,
    this.isNegotiable = false,
    this.isSold = false,
    this.isReserved = false,
    this.isOwner = false,
    this.condition,
    this.categoryName,
    this.city,
    this.district,
    this.deliveryMode = DeliveryMode.pickup,
    this.imageUrls = const [],
    this.photos = const [],
    this.category,
  });

  final String id;

  /// Saisi par le vendeur : à afficher via `userText()`.
  final String title;

  /// Saisi par le vendeur : à afficher via `userText()`.
  final String description;

  /// Prix en dirhams (0 = gratuit).
  final num price;

  /// Prix avant la dernière baisse (calculé par le serveur), barré à
  /// l'écran. Toujours supérieur à [price] quand il est présent.
  final num? previousPrice;

  final bool isNegotiable;
  final bool isSold;

  /// Promise à un acheteur : badge « Réservé », messages toujours possibles.
  final bool isReserved;

  /// Vrai si la personne connectée est le vendeur : la page montre alors
  /// ses actions de vendeur au lieu de « Écrire au vendeur ».
  final bool isOwner;

  /// État de l'article ; null si inconnu.
  final ListingCondition? condition;

  /// Nom de la catégorie (fourni par le serveur) : via `userText()`.
  final String? categoryName;

  /// Identifiants de la liste fixe du serveur (« casablanca », « maarif ») :
  /// le nom affiché vient de `ListingLocations`.
  final String? city;
  final String? district;

  final DeliveryMode deliveryMode;
  final DateTime createdAt;

  /// Adresses web (http ou https) des photos, dans l'ordre du vendeur.
  final List<String> imageUrls;

  /// Photos avec leur identifiant (modification par le vendeur), dans
  /// l'ordre d'affichage.
  final List<RemotePhoto> photos;

  /// Catégorie complète (modification par le vendeur), si connue.
  final ListingCategory? category;

  final ListingSeller seller;

  @override
  bool operator ==(Object other) =>
      other is ListingDetail &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.price == price &&
      other.previousPrice == previousPrice &&
      other.isNegotiable == isNegotiable &&
      other.isSold == isSold &&
      other.isReserved == isReserved &&
      other.isOwner == isOwner &&
      other.condition == condition &&
      other.categoryName == categoryName &&
      other.city == city &&
      other.district == district &&
      other.deliveryMode == deliveryMode &&
      other.createdAt == createdAt &&
      _sameList(other.imageUrls, imageUrls) &&
      _sameList(other.photos, photos) &&
      other.category == category &&
      other.seller == seller;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    price,
    previousPrice,
    isNegotiable,
    isSold,
    isReserved,
    isOwner,
    condition,
    categoryName,
    city,
    district,
    deliveryMode,
    createdAt,
    Object.hashAll(imageUrls),
    Object.hashAll(photos),
    category,
    seller,
  );
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
