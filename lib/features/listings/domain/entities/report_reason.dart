/// Motifs de signalement d'une annonce (mêmes valeurs que le serveur).
enum ReportReason {
  scam('SCAM'),
  prohibitedItem('PROHIBITED_ITEM'),
  offensive('OFFENSIVE'),
  misleading('MISLEADING'),
  spam('SPAM'),
  alreadySold('ALREADY_SOLD'),
  other('OTHER');

  new(this.apiValue);

  /// Valeur envoyée au serveur.
  final String apiValue;

  /// Longueur maximale du détail facultatif (limite du serveur).
  static const maxDetailsLength = 500;
}
