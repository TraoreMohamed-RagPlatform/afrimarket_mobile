import 'package:afrimarket_mobile/features/listings/data/models/listing_json.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_seller.dart';

/// DTO : réponse JSON de `GET /api/listings/:id`.
///
/// ```json
/// { "listing": { "id", "title", "description", "price", "previousPrice",
///   "isNegotiable", "isSold", "status", "condition", "city", "district",
///   "deliveryMode", "createdAt", "category": { "name" },
///   "images": [ { "url" } ],
///   "user": { "id", "username", "fullName", "avatar", "avgRating",
///             "totalRatings", "isIdentityVerified", "createdAt",
///             "responseTimeMinutes", "canCall", "canWhatsapp" } } }
/// ```
///
/// Sécurité (OWASP MASVS - CODE) : champ indispensable invalide (identifiant,
/// titre, prix, date, vendeur) → [FormatException] ; champ facultatif
/// invalide → ignoré. Aucune valeur inconnue n'est affichée telle quelle.
abstract final class ListingDetailModel {
  static const Map<String, ListingCondition> _conditions = {
    'NEW': ListingCondition.brandNew,
    'LIKE_NEW': ListingCondition.likeNew,
    'GOOD': ListingCondition.good,
    'FAIR': ListingCondition.fair,
    'POOR': ListingCondition.poor,
  };

  static const Map<String, DeliveryMode> _deliveryModes = {
    'PICKUP': DeliveryMode.pickup,
    'DELIVERY': DeliveryMode.delivery,
    'BOTH': DeliveryMode.both,
  };

  /// Identifiant de la liste fixe des lieux (« casablanca », « maarif »).
  static final RegExp _locationSlug = RegExp(r'^[a-z0-9-]{1,40}$');

  /// Au-delà, le délai n'est plus une information utile (et une valeur
  /// absurde ne doit pas s'afficher).
  static const int _maxResponseMinutes = 60 * 24 * 30;

  static ListingDetail fromJson(
    Map<String, dynamic> json, {
    required Uri baseUrl,
  }) {
    final listing = json['listing'];
    if (listing is! Map<String, dynamic>) {
      throw const FormatException('Annonce absente');
    }

    final id = ListingJson.safeId(listing['id']);
    final title = ListingJson.nonEmptyText(listing['title']);
    final price = ListingJson.price(listing['price']);
    final createdAt = ListingJson.date(listing['createdAt']);
    final seller = _seller(listing['user'], baseUrl);
    if (id == null ||
        title == null ||
        price == null ||
        createdAt == null ||
        seller == null) {
      throw const FormatException('Annonce invalide');
    }

    final category = listing['category'];
    final description = listing['description'];

    return ListingDetail(
      id: id,
      title: title,
      description: description is String ? description.trim() : '',
      price: price,
      previousPrice: ListingJson.previousPrice(listing['previousPrice'], price),
      isNegotiable: listing['isNegotiable'] == true,
      isSold: listing['isSold'] == true || listing['status'] == 'SOLD',
      condition: _conditions[listing['condition']],
      categoryName: category is Map<String, dynamic>
          ? ListingJson.nonEmptyText(category['name'])
          : null,
      city: _slug(listing['city']),
      district: _slug(listing['district']),
      deliveryMode:
          _deliveryModes[listing['deliveryMode']] ?? DeliveryMode.pickup,
      createdAt: createdAt,
      imageUrls: ListingJson.imageUrls(listing['images'], baseUrl),
      seller: seller,
    );
  }

  static ListingSeller? _seller(Object? json, Uri baseUrl) {
    if (json is! Map<String, dynamic>) return null;
    final id = ListingJson.safeId(json['id']);
    final name =
        ListingJson.nonEmptyText(json['fullName']) ??
        ListingJson.nonEmptyText(json['username']);
    if (id == null || name == null) return null;

    final rating = json['avgRating'];
    final count = json['totalRatings'];
    final response = json['responseTimeMinutes'];
    final canCall = json['canCall'] == true;

    return ListingSeller(
      id: id,
      name: name,
      avatarUrl: ListingJson.webUrl(json['avatar'], baseUrl),
      averageRating: rating is num && rating.isFinite
          ? rating.clamp(0, 5).toDouble()
          : 0,
      ratingCount: count is int && count > 0 ? count : 0,
      isIdentityVerified: json['isIdentityVerified'] == true,
      memberSince: ListingJson.date(json['createdAt']),
      responseTimeMinutes:
          response is int && response >= 0 && response <= _maxResponseMinutes
          ? response
          : null,
      canCall: canCall,
      // WhatsApp passe par le numéro : jamais sans appel possible.
      canWhatsapp: canCall && json['canWhatsapp'] == true,
    );
  }

  static String? _slug(Object? value) =>
      value is String && _locationSlug.hasMatch(value) ? value : null;
}
