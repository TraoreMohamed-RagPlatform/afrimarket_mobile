import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';

/// Lecture prudente des champs d'annonce communs aux réponses du serveur
/// (fil, détail, annonces similaires).
///
/// Sécurité (OWASP MASVS - CODE) : toute donnée du serveur est validée ;
/// une valeur inattendue est ignorée, jamais affichée telle quelle.
abstract final class ListingJson {
  /// Identifiant accepté : 1 à 64 caractères sûrs (mêmes règles que
  /// `RouteAccessPolicy`).
  static final RegExp _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// [value] si c'est un identifiant sûr pour une adresse de l'app.
  static String? safeId(Object? value) =>
      value is String && _safeId.hasMatch(value) ? value : null;

  /// Texte non vide, nettoyé des espaces autour.
  static String? nonEmptyText(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Prix valide : nombre fini, positif ou nul.
  static num? price(Object? value) =>
      value is num && value.isFinite && value >= 0 ? value : null;

  /// Ancien prix : seulement s'il est supérieur au prix actuel.
  static num? previousPrice(Object? value, num current) {
    final previous = price(value);
    return previous != null && previous > current ? previous : null;
  }

  static DateTime? date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// Entier positif, en nombre ou en texte.
  static int? positiveInt(Object? value) {
    if (value is int && value > 0) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  /// Adresse web d'une image : http(s) uniquement ; une adresse relative
  /// (`/uploads/...`) est complétée avec l'adresse du serveur.
  static String? webUrl(Object? raw, Uri baseUrl) {
    if (raw is! String || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final resolved = uri.hasScheme ? uri : baseUrl.resolveUri(uri);
    final isWeb = resolved.scheme == 'https' || resolved.scheme == 'http';
    return isWeb && resolved.host.isNotEmpty ? resolved.toString() : null;
  }

  /// Adresses des photos (`[{ "url" }]`), dans l'ordre reçu ; les
  /// adresses invalides sont ignorées.
  static List<String> imageUrls(Object? images, Uri baseUrl) {
    if (images is! List) return const [];
    return [
      for (final image in images)
        if (image is Map<String, dynamic>) ?webUrl(image['url'], baseUrl),
    ];
  }

  /// Annonce résumée (carte de grille) ; null si elle est mal formée.
  static ListingSummary? summary(Map<String, dynamic> json, Uri baseUrl) {
    final id = safeId(json['id']);
    final title = nonEmptyText(json['title']);
    final amount = price(json['price']);
    final createdAt = date(json['createdAt']);
    if (id == null || title == null || amount == null || createdAt == null) {
      return null;
    }

    final images = imageUrls(json['images'], baseUrl);
    return ListingSummary(
      id: id,
      title: title,
      price: amount,
      previousPrice: previousPrice(json['previousPrice'], amount),
      createdAt: createdAt,
      imageUrl: images.isEmpty ? null : images.first,
      isSold: json['isSold'] == true || json['status'] == 'SOLD',
      isReserved: json['status'] == 'RESERVED',
    );
  }

  /// Liste d'annonces résumées ; les éléments mal formés sont ignorés.
  static List<ListingSummary> summaries(Object? listings, Uri baseUrl) {
    if (listings is! List) {
      throw const FormatException('Liste d’annonces invalide');
    }
    return [
      for (final item in listings)
        if (item is Map<String, dynamic>) ?summary(item, baseUrl),
    ];
  }
}
