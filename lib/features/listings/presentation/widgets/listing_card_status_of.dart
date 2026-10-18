import 'package:afrimarket_mobile/shared/widgets/listing_card_status.dart';

/// Statut métier d'une annonce → statut d'affichage de sa carte.
///
/// « Vendu » l'emporte sur « Réservé ».
ListingCardStatus listingCardStatusOf({
  required bool isSold,
  required bool isReserved,
}) {
  if (isSold) return ListingCardStatus.sold;
  if (isReserved) return ListingCardStatus.reserved;
  return ListingCardStatus.available;
}
