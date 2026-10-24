/// Codes renvoyés par le serveur avec une réponse 409 (`ConflictFailure`)
/// quand une annonce ne peut pas être modifiée.
abstract final class ListingConflicts {
  /// Annonce vendue : plus modifiable.
  static const sold = 'LISTING_SOLD';

  /// Une annonce publiée garde au moins une photo.
  static const lastPhoto = 'LAST_PHOTO';
}
