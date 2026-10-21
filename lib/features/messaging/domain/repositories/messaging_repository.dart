import 'package:afrimarket_mobile/core/error/result.dart';

/// Contrat : messagerie entre acheteurs et vendeurs (connexion requise).
///
/// Une discussion est liée à une annonce : une seule par annonce et par
/// acheteur (comme Facebook Marketplace).
abstract interface class MessagingRepository {
  /// Envoie [message] au vendeur de l'annonce [listingId], dans la
  /// discussion de la personne connectée pour cette annonce (ouverte si
  /// besoin).
  Future<Result<void>> messageSeller({
    required String listingId,
    required String message,
  });
}
