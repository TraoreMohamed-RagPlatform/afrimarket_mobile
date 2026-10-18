import 'package:afrimarket_mobile/features/listings/data/models/listing_json.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_page.dart';

/// DTO : réponse JSON de `GET /api/listings`.
///
/// ```json
/// { "listings": [ { "id", "title", "price", "previousPrice", "createdAt",
///                   "isSold", "images": [ { "url" } ] } ],
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

    final page = ListingJson.positiveInt(pagination['page']) ?? 1;
    final pages = ListingJson.positiveInt(pagination['pages']) ?? 0;

    return ListingPage(
      items: ListingJson.summaries(listings, baseUrl),
      page: page,
      hasMore: page < pages,
    );
  }
}
