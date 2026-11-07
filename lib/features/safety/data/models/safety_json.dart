import 'package:afrimarket_mobile/features/safety/domain/entities/blocked_person.dart';

/// Lecture prudente des réponses de `/api/users/me/blocks`.
///
/// Sécurité (OWASP MASVS - CODE) : identifiants sûrs, adresses http(s)
/// seulement, éléments mal formés ignorés.
abstract final class SafetyJson {
  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static String? _safeId(Object? value) =>
      value is String && _idPattern.hasMatch(value) ? value : null;

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _webUrl(Object? raw, Uri baseUrl) {
    if (raw is! String || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final resolved = uri.hasScheme ? uri : baseUrl.resolveUri(uri);
    final isWeb = resolved.scheme == 'https' || resolved.scheme == 'http';
    return isWeb && resolved.host.isNotEmpty ? resolved.toString() : null;
  }

  static BlockedPerson? _blocked(Object? json, Uri baseUrl) {
    if (json is! Map<String, dynamic>) return null;
    final id = _safeId(json['userId']);
    final at = json['blockedAt'];
    final blockedAt = at is String ? DateTime.tryParse(at) : null;
    if (id == null || blockedAt == null) return null;
    return BlockedPerson(
      userId: id,
      name: _text(json['name']),
      avatarUrl: _webUrl(json['avatar'], baseUrl),
      blockedAt: blockedAt,
    );
  }

  /// `{ blocks: [...] }` ; sans liste : [FormatException].
  static List<BlockedPerson> blocks(Object? json, Uri baseUrl) {
    if (json is! Map<String, dynamic> || json['blocks'] is! List) {
      throw const FormatException('Liste invalide');
    }
    return [
      for (final item in json['blocks'] as List) ?_blocked(item, baseUrl),
    ];
  }
}
