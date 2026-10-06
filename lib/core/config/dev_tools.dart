import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:flutter/foundation.dart';

/// Outils de développement (page Diagnostic, Galerie) compilés dans l'app.
///
/// Constante fixée À LA COMPILATION (`DEV_TOOLS` dans config/*.json) :
/// quand elle vaut `false` (staging, prod), le compilateur RETIRE du
/// binaire tout le code qui en dépend (tree shaking). Les outils de dev
/// n'existent alors pas physiquement dans l'app publiée.
///
/// Sécurité (OWASP MASVS - RESILIENCE) : réduction de la surface
/// d'attaque ; un APK décompilé ne contient pas ces outils.
///
/// Sans valeur (tests automatiques) : vraie en mode debug seulement.
const bool kDevToolsEnabled = bool.fromEnvironment(
  'DEV_TOOLS',
  defaultValue: kDebugMode,
);

/// Vrai si les outils de dev doivent être proposés.
///
/// Double protection : outils compilés ([kDevToolsEnabled], vérifié à la
/// compilation) ET environnement de développement (vérifié à
/// l'exécution). Une erreur de configuration d'un seul côté ne suffit pas
/// à exposer les outils.
bool devToolsVisible(Flavor flavor) => kDevToolsEnabled && flavor == Flavor.dev;
