import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:meta/meta.dart';

/// Photo choisie sur le téléphone, pas encore envoyée.
@immutable
final class LocalPhoto {
  const new(this.path);

  /// Chemin du fichier sur le téléphone.
  final String path;

  @override
  bool operator ==(Object other) => other is LocalPhoto && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

/// Ce qui manque ou ne va pas dans une annonce avant publication.
enum DraftProblem {
  noPhoto,
  titleTooShort,
  noPrice,
  priceTooHigh,
  noCategory,
  noDistrict,
  noCondition,
  descriptionTooShort,
}

/// Annonce en cours de saisie (écran « Publier »).
///
/// Entité métier : Dart pur. Les limites sont celles du serveur.
@immutable
final class ListingDraft {
  const new({
    this.photos = const [],
    this.title = '',
    this.price,
    this.categoryId,
    this.city = defaultCity,
    this.district,
    this.condition,
    this.description = '',
    this.isNegotiable = false,
    this.deliveryMode = DeliveryMode.pickup,
  });

  static const empty = ListingDraft();

  /// Ville proposée (lancement à Casablanca).
  static const defaultCity = 'casablanca';

  /// Photos par annonce (comme Facebook Marketplace).
  static const maxPhotos = 10;

  static const titleMinLength = 3;
  static const titleMaxLength = 100;
  static const descriptionMinLength = 10;
  static const descriptionMaxLength = 5000;

  /// Prix maximal accepté par le serveur (DH).
  static const maxPrice = 100000000;

  /// La première photo est la photo principale (carte du fil).
  final List<LocalPhoto> photos;
  final String title;

  /// En dirhams ; 0 = gratuit ; null = pas encore saisi.
  final int? price;
  final String? categoryId;
  final String city;
  final String? district;
  final ListingCondition? condition;
  final String description;
  final bool isNegotiable;
  final DeliveryMode deliveryMode;

  /// Vrai si rien n'a encore été saisi (quitter sans confirmation).
  bool get isEmpty => this == empty;

  /// Ce qui empêche la publication ; vide = prête.
  Set<DraftProblem> get problems {
    final price = this.price;
    return {
      if (photos.isEmpty) DraftProblem.noPhoto,
      if (title.trim().length < titleMinLength) DraftProblem.titleTooShort,
      if (price == null) DraftProblem.noPrice,
      if (price != null && price > maxPrice) DraftProblem.priceTooHigh,
      if (categoryId == null) DraftProblem.noCategory,
      if (district == null) DraftProblem.noDistrict,
      if (condition == null) DraftProblem.noCondition,
      if (description.trim().length < descriptionMinLength)
        DraftProblem.descriptionTooShort,
    };
  }

  bool get isReady => problems.isEmpty;

  ListingDraft copyWith({
    List<LocalPhoto>? photos,
    String? title,
    int? Function()? price,
    String? categoryId,
    String? district,
    ListingCondition? condition,
    String? description,
    bool? isNegotiable,
    DeliveryMode? deliveryMode,
  }) {
    return ListingDraft(
      photos: photos ?? this.photos,
      title: title ?? this.title,
      price: price == null ? this.price : price(),
      categoryId: categoryId ?? this.categoryId,
      city: city,
      district: district ?? this.district,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      deliveryMode: deliveryMode ?? this.deliveryMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ListingDraft &&
      _samePhotos(other.photos, photos) &&
      other.title == title &&
      other.price == price &&
      other.categoryId == categoryId &&
      other.city == city &&
      other.district == district &&
      other.condition == condition &&
      other.description == description &&
      other.isNegotiable == isNegotiable &&
      other.deliveryMode == deliveryMode;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(photos),
    title,
    price,
    categoryId,
    city,
    district,
    condition,
    description,
    isNegotiable,
    deliveryMode,
  );
}

bool _samePhotos(List<LocalPhoto> a, List<LocalPhoto> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
