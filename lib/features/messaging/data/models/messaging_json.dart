import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/chat_message.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';

/// Lecture prudente des réponses de `/api/messages`.
///
/// Sécurité (OWASP MASVS - CODE) : toute donnée du serveur est validée ;
/// un élément mal formé est ignoré (liste) ou refusé (élément seul),
/// jamais affiché tel quel.
abstract final class MessagingJson {
  /// Identifiant accepté (mêmes règles que les adresses de l'app).
  static final RegExp _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static String? safeId(Object? value) =>
      value is String && _safeId.hasMatch(value) ? value : null;

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// Adresse d'image http(s) ; relative (`/uploads/...`) : complétée avec
  /// l'adresse du serveur.
  static String? _webUrl(Object? raw, Uri baseUrl) {
    if (raw is! String || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final resolved = uri.hasScheme ? uri : baseUrl.resolveUri(uri);
    final isWeb = resolved.scheme == 'https' || resolved.scheme == 'http';
    return isWeb && resolved.host.isNotEmpty ? resolved.toString() : null;
  }

  static ConversationListingStatus _status(Object? value) => switch (value) {
    'ACTIVE' => ConversationListingStatus.available,
    'RESERVED' => ConversationListingStatus.reserved,
    'SOLD' => ConversationListingStatus.sold,
    _ => ConversationListingStatus.unavailable,
  };

  static ConversationListing? _listing(Object? json, Uri baseUrl) {
    if (json is! Map<String, dynamic>) return null;
    final id = safeId(json['id']);
    final title = _text(json['title']);
    final price = json['price'];
    if (id == null || title == null || price is! num || !price.isFinite) {
      return null;
    }
    return ConversationListing(
      id: id,
      title: title,
      price: price < 0 ? 0 : price,
      status: _status(json['status']),
      photoUrl: _webUrl(json['photo'], baseUrl),
    );
  }

  static ConversationPerson? _person(Object? json, Uri baseUrl) {
    if (json is! Map<String, dynamic>) return null;
    final id = safeId(json['id']);
    if (id == null) return null;
    return ConversationPerson(
      id: id,
      name: _text(json['name']),
      avatarUrl: _webUrl(json['avatar'], baseUrl),
      isIdentityVerified: json['isIdentityVerified'] == true,
      canReceiveMessages: json['canReceiveMessages'] != false,
    );
  }

  static MessagePreview? _preview(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final text = _text(json['preview']);
    final sentAt = _date(json['createdAt']);
    if (text == null || sentAt == null) return null;
    return MessagePreview(
      text: text,
      isMine: json['isMine'] == true,
      sentAt: sentAt,
    );
  }

  static int _count(Object? value) => value is int && value > 0 ? value : 0;

  /// Une discussion ; `null` si elle est mal formée.
  static ConversationSummary? conversation(Object? json, Uri baseUrl) {
    if (json is! Map<String, dynamic>) return null;
    final id = safeId(json['id']);
    final role = switch (json['role']) {
      'buying' => ConversationRole.buying,
      'selling' => ConversationRole.selling,
      _ => null,
    };
    final other = _person(json['otherUser'], baseUrl);
    if (id == null || role == null || other == null) return null;
    return ConversationSummary(
      id: id,
      role: role,
      otherUser: other,
      listing: _listing(json['listing'], baseUrl),
      lastMessage: _preview(json['lastMessage']),
      unreadCount: _count(json['unreadCount']),
    );
  }

  /// Un message ; `null` s'il est mal formé.
  static ChatMessage? message(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = safeId(json['id']);
    final content = json['content'];
    final sentAt = _date(json['createdAt']);
    if (id == null || content is! String || content.isEmpty || sentAt == null) {
      return null;
    }
    return ChatMessage(
      id: id,
      text: content,
      isMine: json['isMine'] == true,
      sentAt: sentAt,
      readAt: _date(json['readAt']),
    );
  }

  /// Page `{ <key>: [...], nextCursor }` ; les éléments mal formés sont
  /// ignorés, une page sans liste est refusée.
  static CursorPage<T> page<T>(
    Object? json,
    String key,
    T? Function(Object? item) read,
  ) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Page invalide');
    }
    final items = json[key];
    if (items is! List) throw const FormatException('Page invalide');
    return CursorPage(
      items: [for (final item in items) ?read(item)],
      nextCursor: safeId(json['nextCursor']),
    );
  }
}
