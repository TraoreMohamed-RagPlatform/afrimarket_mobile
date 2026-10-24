import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/features/notifications/domain/entities/app_notification.dart';

/// Lecture prudente des réponses de `/api/notifications`.
///
/// Sécurité (OWASP MASVS - CODE) : identifiants sûrs, adresses http(s)
/// seulement, éléments mal formés ignorés ; un type inconnu devient
/// [NotificationKind.system] (texte du serveur), jamais une erreur.
abstract final class NotificationsJson {
  static final RegExp _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static String? safeId(Object? value) =>
      value is String && _safeId.hasMatch(value) ? value : null;

  static String _text(Object? value) => value is String ? value.trim() : '';

  static String? _webUrl(Object? raw, Uri baseUrl) {
    if (raw is! String || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final resolved = uri.hasScheme ? uri : baseUrl.resolveUri(uri);
    final isWeb = resolved.scheme == 'https' || resolved.scheme == 'http';
    return isWeb && resolved.host.isNotEmpty ? resolved.toString() : null;
  }

  static NotificationKind _kind(Object? value) => switch (value) {
    'LISTING_INTEREST' => NotificationKind.listingInterest,
    'RATING_RECEIVED' => NotificationKind.ratingReceived,
    'LISTING_SOLD' => NotificationKind.listingSold,
    'LISTING_UPDATED' => NotificationKind.listingUpdated,
    'PRICE_DROP' => NotificationKind.priceDrop,
    'MESSAGE' => NotificationKind.message,
    _ => NotificationKind.system,
  };

  static NotificationListing? _listing(Object? json, Uri baseUrl) {
    if (json is! Map<String, dynamic>) return null;
    final id = safeId(json['id']);
    final title = _text(json['title']);
    if (id == null || title.isEmpty) return null;
    return NotificationListing(
      id: id,
      title: title,
      status: switch (json['status']) {
        'ACTIVE' => NotificationListingStatus.available,
        'RESERVED' => NotificationListingStatus.reserved,
        'SOLD' => NotificationListingStatus.sold,
        _ => NotificationListingStatus.unavailable,
      },
      photoUrl: _webUrl(json['photo'], baseUrl),
    );
  }

  /// Une notification ; `null` si elle est mal formée.
  static AppNotification? notification(Object? json, Uri baseUrl) {
    if (json is! Map<String, dynamic>) return null;
    final id = safeId(json['id']);
    final createdAt = json['createdAt'] is String
        ? DateTime.tryParse(json['createdAt'] as String)
        : null;
    if (id == null || createdAt == null) return null;
    return AppNotification(
      id: id,
      kind: _kind(json['type']),
      createdAt: createdAt,
      title: _text(json['title']),
      message: _text(json['message']),
      read: json['read'] == true,
      listing: _listing(json['listing'], baseUrl),
    );
  }

  /// Page `{ notifications: [...], nextCursor }`.
  static CursorPage<AppNotification> page(Object? json, Uri baseUrl) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Page invalide');
    }
    final items = json['notifications'];
    if (items is! List) throw const FormatException('Page invalide');
    return CursorPage(
      items: [for (final item in items) ?notification(item, baseUrl)],
      nextCursor: safeId(json['nextCursor']),
    );
  }
}
