/// Motifs de signalement d'une personne (mêmes valeurs que le serveur).
enum PersonReportReason {
  scam('SCAM'),
  harassment('HARASSMENT'),
  spam('SPAM'),
  offensive('OFFENSIVE'),
  fakeProfile('FAKE_PROFILE'),
  other('OTHER');

  new(this.apiValue);

  /// Valeur envoyée au serveur.
  final String apiValue;

  /// Longueur maximale du détail facultatif (limite du serveur).
  static const maxDetailsLength = 500;

  /// Derniers messages de la discussion joints au signalement (le serveur
  /// les copie ; la feuille le dit avant l'envoi).
  static const copiedMessages = 20;
}
