# ADR 0008 — Outils de développement retirés du binaire de production

- **Statut** : accepté
- **Date** : 2026-10-06 (phase F2e)

## Contexte

Les outils de développement (page Diagnostic, Galerie) n'étaient
masqués en production que pendant l'exécution : leur code restait
compilé dans l'APK, lisible après décompilation.

## Décision

- Constante de compilation `kDevToolsEnabled`
  (`bool.fromEnvironment('DEV_TOOLS')`), fixée dans `config/*.json` :
  `true` en dev, `false` en staging et en prod. Sans valeur (tests),
  vraie en mode debug.
- Règle unique `devToolsVisible(flavor)` : constante de compilation ET
  flavor dev (double protection).
- Le compilateur retire du binaire release tout code qui en dépend
  (tree shaking).

## Sécurité (OWASP MASVS - RESILIENCE)

Réduction de la surface d'attaque : un APK de production décompilé ne
contient ni les écrans, ni la logique des outils de développement.

## Conséquences

- Tout nouvel outil de développement passe par `devToolsVisible()`.
- Le retrait effectif ne concerne que les builds **release** (celui du
  pipeline). Un lancement « prod » en mode debug masque les outils sans
  les retirer.
- Piste complémentaire : obfuscation des builds de production
  (`--obfuscate --split-debug-info`), à étudier avant publication.