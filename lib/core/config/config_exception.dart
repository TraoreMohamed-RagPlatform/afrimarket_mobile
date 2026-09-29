/// Erreur de configuration détectée au démarrage.
///
/// Elle est volontairement bloquante : une application mal configurée
/// (par exemple une production sans HTTPS) ne doit jamais démarrer.
class ConfigException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'ConfigException: $message';
}
