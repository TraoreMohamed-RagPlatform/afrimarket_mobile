import 'package:afrimarket_mobile/features/auth/domain/entities/auth_user.dart';

/// DTO : réponse JSON de la connexion et de l'inscription.
///
/// ```json
/// { "user": { "id", "email", "username", "fullName" },
///   "accessToken": "...", "refreshToken": "..." }
/// ```
///
/// Sécurité : les types sont VALIDÉS. Une réponse inattendue lève une
/// [FormatException], convertie en `UnexpectedFailure` par guardApiCall.
/// [toString] ne révèle jamais les tokens.
class AuthSessionModel {
  const new({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Champ « user » manquant ou invalide');
    }
    return AuthSessionModel(
      accessToken: _requireString(json, 'accessToken'),
      refreshToken: _requireString(json, 'refreshToken'),
      user: AuthUser(
        id: _requireString(user, 'id'),
        email: _requireString(user, 'email'),
        username: _requireString(user, 'username'),
        fullName: _requireString(user, 'fullName', allowEmpty: true),
      ),
    );
  }

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  @override
  String toString() => 'AuthSessionModel(user: ${user.id}, tokens: ***)';

  static String _requireString(
    Map<String, dynamic> json,
    String key, {
    bool allowEmpty = false,
  }) {
    final value = json[key];
    if (value is! String || (!allowEmpty && value.isEmpty)) {
      throw FormatException('Champ « $key » manquant ou invalide');
    }
    return value;
  }
}
