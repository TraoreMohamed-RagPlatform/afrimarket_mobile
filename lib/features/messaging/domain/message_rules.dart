/// Règles d'un message (les mêmes que le serveur).
abstract final class MessageRules {
  /// Longueur maximale, en caractères, une fois les espaces retirés.
  static const maxLength = 1000;

  /// Texte prêt à envoyer, ou `null` s'il est vide ou trop long.
  static String? clean(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.runes.length > maxLength) return null;
    return trimmed;
  }
}
