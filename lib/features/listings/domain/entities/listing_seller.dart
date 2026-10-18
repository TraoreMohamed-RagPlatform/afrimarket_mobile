import 'package:meta/meta.dart';

/// Vendeur, tel qu'il apparaît sur une annonce.
///
/// Sécurité : son numéro n'est JAMAIS ici. Il s'obtient à la demande,
/// connecté, via `fetchSellerContact` ; [canCall] dit seulement si
/// l'appel est possible (numéro vérifié ET partagé par le vendeur).
@immutable
final class ListingSeller {
  const new({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.averageRating = 0,
    this.ratingCount = 0,
    this.isIdentityVerified = false,
    this.memberSince,
    this.responseTimeMinutes,
    this.canCall = false,
    this.canWhatsapp = false,
  });

  final String id;

  /// Nom affiché (saisi par l'utilisateur) : via `userText()`.
  final String name;

  final String? avatarUrl;
  final double averageRating;
  final int ratingCount;
  final bool isIdentityVerified;

  /// Date d'inscription (« Membre depuis 2025 »).
  final DateTime? memberSince;

  /// Délai de réponse habituel ; null tant que le serveur n'a pas assez
  /// de réponses pour l'estimer.
  final int? responseTimeMinutes;

  final bool canCall;
  final bool canWhatsapp;

  @override
  bool operator ==(Object other) =>
      other is ListingSeller &&
      other.id == id &&
      other.name == name &&
      other.avatarUrl == avatarUrl &&
      other.averageRating == averageRating &&
      other.ratingCount == ratingCount &&
      other.isIdentityVerified == isIdentityVerified &&
      other.memberSince == memberSince &&
      other.responseTimeMinutes == responseTimeMinutes &&
      other.canCall == canCall &&
      other.canWhatsapp == canWhatsapp;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    avatarUrl,
    averageRating,
    ratingCount,
    isIdentityVerified,
    memberSince,
    responseTimeMinutes,
    canCall,
    canWhatsapp,
  );
}
