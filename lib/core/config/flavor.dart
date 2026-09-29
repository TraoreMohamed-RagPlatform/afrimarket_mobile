/// Environnements d'exécution de l'application.
enum Flavor {
  dev,
  staging,
  prod;

  /// HTTPS est obligatoire partout sauf en développement local.
  bool get requiresHttps => this != Flavor.dev;
}
