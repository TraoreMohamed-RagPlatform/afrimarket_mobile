/// Codes renvoyés par le serveur avec une réponse 409 (`ConflictFailure`)
/// quand un message ne peut pas être envoyé.
abstract final class MessagingConflicts {
  /// Annonce vendue ou retirée : pas de nouvelle discussion.
  static const listingUnavailable = 'LISTING_UNAVAILABLE';

  /// Compte de l'autre personne suspendu ou supprimé.
  static const recipientUnavailable = 'RECIPIENT_UNAVAILABLE';
}
