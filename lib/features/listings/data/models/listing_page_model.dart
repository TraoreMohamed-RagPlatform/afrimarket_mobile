import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';

/// DTO : réponse JSON de `GET /api/listings`.
///
/// ```json
/// { "listings": [ { "id", "title", "price", "createdAt", "isSold",
///                   "images": [ { "url" } ] } ],
///   "pagination": { "page", "limit", "total", "pages" } }
/// ```
///
/// Sécurité (OWASP MASVS - CODE) : toute donnée du serveur est validée.
/// - une réponse mal formée lève une [FormatException], convertie en
///   `UnexpectedFailure` par `guardApiCall` ;
/// - une annonce mal formée est ignorée (le reste du fil s'affiche) ;
/// - l'identifiant doit être sûr pour une adresse de l'app (mêmes règles
///   que `RouteAccessPolicy`) ;
/// - seules les photos http(s) sont gardées ; une adresse relative
///   (`/uploads/...`) est complétée avec l'adresse du serveur.
abstract final class ListingPageModel {
  /// Identifiant accepté : 1 à 64 caractères sûrs.
  static final RegExp _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// Convertit la réponse ; [baseUrl] sert à compléter les adresses de
  /// photos relatives.
  static ListingPage fromJson(
    Map<String, dynamic> json, {
    required Uri baseUrl,
  }) {
    final listings = json['listings'];
    final pagination = json['pagination'];
    if (listings is! List || pagination is! Map<String, dynamic>) {
      throw const FormatException('Réponse du fil invalide');
    }

    final page = _positiveInt(pagination['page']) ?? 1;
    final pages = _positiveInt(pagination['pages']) ?? 0;

    return ListingPage(
      items: [
        for (final item in listings)
          if (item is Map<String, dynamic>) ?_summary(item, baseUrl),
      ],
      page: page,
      hasMore: page < pages,
    );
  }

  static ListingSummary? _summary(Map<String, dynamic> json, Uri baseUrl) {
    final id = json['id'];
    final title = json['title'];
    final price = json['price'];
    final createdAt = json['createdAt'];
    if (id is! String || !_safeId.hasMatch(id)) return null;
    if (title is! String || title.trim().isEmpty) return null;
    if (price is! num || !price.isFinite || price < 0) return null;
    if (createdAt is! String) return null;
    final date = DateTime.tryParse(createdAt);
    if (date == null) return null;

    return ListingSummary(
      id: id,
      title: title.trim(),
      price: price,
      createdAt: date,
      imageUrl: _firstImageUrl(json['images'], baseUrl),
      isSold: json['isSold'] == true,
    );
  }

  static String? _firstImageUrl(Object? images, Uri baseUrl) {
    if (images is! List) return null;
    for (final image in images) {
      if (image is! Map<String, dynamic>) continue;
      final raw = image['url'];
      if (raw is! String || raw.trim().isEmpty) continue;
      final uri = Uri.tryParse(raw.trim());
      if (uri == null) continue;
      final resolved = uri.hasScheme ? uri : baseUrl.resolveUri(uri);
      final isWeb = resolved.scheme == 'https' || resolved.scheme == 'http';
      if (isWeb && resolved.host.isNotEmpty) return resolved.toString();
    }
    return null;
  }

  static int? _positiveInt(Object? value) {
    if (value is int && value > 0) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }
}
