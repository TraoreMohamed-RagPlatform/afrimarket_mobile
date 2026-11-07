/// Codes renvoyés par le serveur avec une réponse 409 (`ConflictFailure`).
abstract final class SafetyConflicts {
  /// Cette personne est déjà signalée depuis cette discussion.
  static const alreadyReported = 'ALREADY_REPORTED';
}
