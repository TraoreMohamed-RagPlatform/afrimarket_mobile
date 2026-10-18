import 'package:afrimarket_mobile/core/error/result.dart';

/// Contrat : messagerie entre utilisateurs (connexion requise).
abstract interface class MessagingRepository {
  /// Envoie [message] au vendeur [sellerId], dans leur conversation
  /// (créée si besoin).
  Future<Result<void>> messageSeller({
    required String sellerId,
    required String message,
  });
}
