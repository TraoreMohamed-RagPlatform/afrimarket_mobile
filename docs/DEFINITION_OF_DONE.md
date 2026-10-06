# Definition of Done — AfriMarket Mobile

Une modification est **terminée** uniquement si **tous** les points
ci-dessous sont respectés. Cette liste est reprise automatiquement dans
chaque Pull Request (`.github/pull_request_template.md`).

L'application est conçue pour **grandir** : chaque point vise à ce qu'une
nouvelle fonctionnalité puisse être ajoutée sans casser l'existant.

## 1. Architecture et évolutivité

| Règle | Pourquoi |
|---|---|
| Le code est placé selon [`ARCHITECTURE.md`](ARCHITECTURE.md) et respecte les règles de dépendance | Garder chaque couche remplaçable et testable |
| Une fonctionnalité n'importe jamais le dossier `data/` d'une autre | Éviter que les fonctionnalités deviennent dépendantes entre elles |
| Un widget partagé est **autonome** (ne suppose ni `Scaffold`, ni fonctionnalité précise) | Pouvoir le réutiliser partout : page, feuille, boîte de dialogue |
| Les **points d'extension** des fonctionnalités futures sont prévus, sans implémenter de fonctionnalité spéculative | Principe ouvert / fermé (SOLID) sans sur-conception (YAGNI) |
| Noms de routes dans `core/navigation/`, injection dans `<feature>_providers.dart` | Un seul endroit pour chaque responsabilité |

## 2. Qualité du code

| Règle | Pourquoi |
|---|---|
| `dart fix`, `dart format` et `flutter analyze` : **0 remarque** | Code homogène ; le pipeline le vérifie |
| Aucun texte, couleur ou dimension en dur (traductions, `AppColors`, `AppSpacing`) | Traductions, mode sombre et cohérence visuelle automatiques |
| Les erreurs passent par `Result` / `Failure` | Aucune erreur oubliée, aucun détail technique affiché |
| Classes et méthodes publiques documentées (`///`) | Compréhension rapide par tout développeur |

## 3. Sécurité (OWASP MASVS v2)

| Règle | Pourquoi |
|---|---|
| Aucun secret dans le code ni dans `config/` | Le dépôt est public |
| Aucune donnée personnelle ni token dans les logs | PRIVACY : les logs peuvent être lus ou partagés |
| Toute donnée externe est validée (JSON, URL, saisies) | Une donnée inattendue ne doit ni planter l'app, ni ouvrir de faille |
| Moindre privilège (token uniquement si nécessaire, permissions minimales) | Réduire l'impact d'une éventuelle fuite |

## 4. Accessibilité et traductions

| Règle | Pourquoi |
|---|---|
| Contraste WCAG 2.1 AA (couleurs du thème uniquement) | Lisibilité pour tous ; vérifié par les tests |
| Libellés pour lecteurs d'écran sur tout élément interactif | Utilisable par les personnes malvoyantes |
| Zones tactiles d'au moins 48 × 48 | Norme Material : éviter les erreurs de toucher |
| Aucun débordement avec une taille de texte doublée | Réglage fréquent chez les personnes âgées ou malvoyantes |
| Mise en page compatible droite à gauche (`start` / `end`) | L'arabe est une langue de l'app |
| Nouveaux textes ajoutés dans les 3 fichiers ARB | Le test de cohérence bloque sinon le pipeline |
| Tout texte saisi par un utilisateur (titre, description, message, nom) est affiché via `userText()` | Ponctuation correcte entre langues de sens différents, et protection contre l'usurpation d'affichage (CWE-451) |

## 5. Visuel

| Règle | Pourquoi |
|---|---|
| Vérifié en mode clair et en mode sombre | Les deux modes sont proposés aux utilisateurs |
| Conforme à la maquette ou à l'aperçu validé | Pas de surprise visuelle |

## 6. Tests

| Règle | Pourquoi |
|---|---|
| Tests unitaires (logique) et tests de widgets (interface) | Détecter les régressions avant `main` |
| Tests de widgets en arabe, en mode sombre et avec un grand texte | Les cas les plus souvent oubliés |
| Cas limites testés (vide, erreur, valeur nulle, données invalides) | C'est là que se cachent les bugs |
| `test/` reproduit l'arborescence de `lib/` | Retrouver les tests d'un fichier immédiatement |

## 7. Documentation et Git

| Règle | Pourquoi |
|---|---|
| `ARCHITECTURE.md` ou un ADR mis à jour si une décision est prise | Garder la trace du **pourquoi** |
| Branche `feat/…`, `fix/…`, `security/…`, `chore/…` | `main` est protégé : tout passe par une Pull Request |
| Commits au format Conventional Commits | Historique lisible |
| Pipeline vert avant la fusion | Garantie automatique de qualité et de sécurité |