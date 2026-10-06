/// Statut d'AFFICHAGE d'une carte d'annonce.
///
/// Volontairement séparé du statut métier : un widget partagé ne dépend
/// d'aucune fonctionnalité. La fonctionnalité « listings » convertit son
/// propre statut vers celui-ci ; un nouveau statut côté backend ne
/// demande donc qu'une modification de cette conversion.
enum ListingCardStatus {
  /// Annonce disponible (affichage normal).
  available,

  /// Annonce réservée : badge « Réservé ».
  reserved,

  /// Annonce vendue : photo en noir et blanc, atténuée, mention « Vendu ».
  sold,
}
