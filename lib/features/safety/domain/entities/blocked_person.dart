import 'package:meta/meta.dart';

/// Personne que j'ai bloquée (Réglages → Personnes bloquées).
@immutable
final class BlockedPerson {
  const new({
    required this.userId,
    required this.blockedAt,
    this.name,
    this.avatarUrl,
  });

  final String userId;

  /// Nom affiché ; `null` pour un compte supprimé.
  final String? name;
  final String? avatarUrl;
  final DateTime blockedAt;
}
