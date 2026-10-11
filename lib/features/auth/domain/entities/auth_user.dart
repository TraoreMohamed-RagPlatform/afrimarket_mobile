import 'package:meta/meta.dart';

/// Utilisateur connecté, tel que renvoyé par la connexion ou l'inscription.
///
/// Entité métier : Dart pur, sans dépendance à Flutter ni à l'API.
@immutable
final class AuthUser {
  const new({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
  });

  final String id;
  final String email;
  final String username;
  final String fullName;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.email == email &&
      other.username == username &&
      other.fullName == fullName;

  @override
  int get hashCode => Object.hash(id, email, username, fullName);
}
