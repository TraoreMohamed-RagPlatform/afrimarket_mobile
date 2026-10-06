# Architecture — AfriMarket Mobile

Ce document définit les **règles obligatoires** du projet. Toute contribution
doit les respecter. Les décisions et leurs justifications sont dans
[`docs/adr/`](adr/).

## 1. Normes de référence

| Domaine | Norme |
|---|---|
| Architecture | Clean Architecture + SOLID ([ADR 0001](adr/0001-clean-architecture-feature-first.md)) |
| Sécurité mobile | OWASP MASVS v2 |
| Style de code | Effective Dart + `very_good_analysis` |
| Git | Conventional Commits + SemVer |
| Décisions techniques | ADR (Architecture Decision Records) |

## 2. Structure du projet

```
lib/
├── main_dev.dart / main_staging.dart / main_prod.dart
├── app/                  # Racine de l'app, bootstrap, routeur et gardes
│   ├── pages/            #   Pages transverses (splash, page introuvable)
│   └── router/           #   GoRouter + resolveRedirect
├── core/                 # Socle technique (aucune logique métier)
│   ├── config/           #   Environnements, flavors
│   ├── network/          #   Dio, intercepteurs, endpoints
│   ├── error/            #   Result, Failures
│   ├── storage/          #   Stockage sécurisé, tokens
│   ├── navigation/       #   Noms des routes (AppRoutes)
│   ├── session/          #   État de session (connecté / déconnecté)
│   ├── security/         #   Pinning, intégrité de l'appareil
│   ├── logging/          #   Logger
│   ├── l10n/             #   Traductions FR / EN / AR
│   └── theme/            #   Design tokens
├── shared/               # Widgets et extensions réutilisables
└── features/<nom>/
    ├── data/
    │   ├── datasources/  #   Appels API
    │   ├── models/       #   DTO (JSON)
    │   └── repositories/ #   Implémentations
    ├── domain/
    │   ├── entities/     #   Objets métier purs
    │   ├── repositories/ #   Contrats (classes abstraites)
    │   └── usecases/     #   Actions métier
    └── presentation/
        ├── pages/
        ├── widgets/
        └── controllers/  #   État Riverpod
test/                     # Même arborescence que lib/
config/                   # dev.json, staging.json, prod.json (valeurs PUBLIQUES)
```

## 3. Règles de dépendance (obligatoires)

```
presentation  ──►  domain  ◄──  data
```

| Couche | Peut importer | Ne doit JAMAIS importer |
|---|---|---|
| `domain` | Dart pur, `core/error` | Flutter, Dio, `data/`, `presentation/` |
| `data` | `domain`, `core/` | `presentation/` |
| `presentation` | `domain`, `core/`, `shared/` | `data/` (sauf les providers d'injection) |
| `core` | Packages externes | `features/`, `app/` |
| `shared` | `core/` | `features/`, `app/` |
| `app` | `features/`, `core/`, `shared/` | — (rien n'importe `app/`, sauf les points d'entrée `main_*.dart`) |

**Entre fonctionnalités :** une feature n'importe **jamais** le dossier `data/`
d'une autre feature. Si deux features partagent un besoin, il est remonté dans
`core/` ou `shared/`.

**Navigation :** les noms de routes sont dans `core/navigation/` (accessibles à
toutes les features). Le routeur lui-même et ses gardes sont dans `app/router/`.
La protection des pages est centralisée dans `resolveRedirect` : une nouvelle
page protégée ne nécessite aucun code de sécurité supplémentaire.

## 4. Conventions de nommage

| Élément | Fichier | Classe |
|---|---|---|
| Page | `login_page.dart` | `LoginPage` |
| Widget | `listing_card.dart` | `ListingCard` |
| Contrôleur | `login_controller.dart` | `LoginController` |
| Cas d'usage | `login_usecase.dart` | `LoginUseCase` |
| Contrat | `auth_repository.dart` | `AuthRepository` |
| Implémentation | `auth_repository_impl.dart` | `AuthRepositoryImpl` |
| Source de données | `auth_remote_datasource.dart` | `AuthRemoteDataSource` |
| DTO | `user_model.dart` | `UserModel` |
| Entité | `user.dart` | `User` |

Fichiers et dossiers en `snake_case`, classes en `PascalCase`, variables en
`camelCase`.

## 5. Gestion des erreurs

- Chaque appel API est enveloppé dans `guardApiCall()`, qui renvoie un
  `Result<T>` (`Ok` ou `Err`) : jamais d'exception non gérée vers l'interface.
- Toute erreur technique (réseau, HTTP, JSON) devient une `Failure` typée
  (`mapDioException`).
- `Failure` est une classe scellée : un `switch` doit traiter tous les cas,
  sinon le code ne compile pas.
- Le texte des erreurs du serveur n'est **jamais** repris (sauf les messages de
  validation par champ). Les messages affichés sont traduits et ne révèlent
  aucun détail technique.

## 6. Environnements

| Flavor | Application ID | API | Usage |
|---|---|---|---|
| `dev` | `com.afrimarket.afrimarket_mobile.dev` | Backend local (HTTP autorisé en debug) | Développement |
| `staging` | `com.afrimarket.afrimarket_mobile.staging` | Serveur de test (HTTPS) | Recette |
| `prod` | `com.afrimarket.afrimarket_mobile` | Serveur de production (HTTPS) | Utilisateurs |

La configuration est injectée au build avec
`--dart-define-from-file=config/<env>.json` et **validée au démarrage**
(`AppConfig`) : l'app refuse de démarrer si HTTPS n'est pas utilisé en staging
ou en production. Les fichiers `config/*.json` ne contiennent **que des valeurs
publiques** : jamais de clé, mot de passe ou secret.

## 7. Internationalisation

- Langues : **français** (par défaut), **anglais**, **arabe**.
- Aucun texte affiché n'est écrit en dur : tout passe par les fichiers ARB.
- L'arabe s'affiche de **droite à gauche (RTL)** : utiliser
  `EdgeInsetsDirectional`, `AlignmentDirectional`, `start` / `end`,
  jamais `left` / `right`.

## 8. Sécurité (OWASP MASVS v2)

| Catégorie | Règle |
|---|---|
| **STORAGE** | Tokens et secrets uniquement via `SecureStorage` (Keystore / Keychain). Sauvegarde Android désactivée (`allowBackup="false"`). Le refresh token n'est jamais gardé en mémoire. |
| **NETWORK** | HTTPS obligatoire en staging / prod (vérifié au démarrage). HTTP autorisé uniquement en debug vers le backend local. Redirections HTTP désactivées. Le token n'est envoyé **qu'à notre API** (même protocole, serveur et port). |
| **AUTH** | Refresh automatique : un seul refresh simultané, pas de boucle, session effacée seulement si le serveur refuse. Session « fermée par défaut » en cas d'erreur. Session expirée : retour automatique à la connexion. Paramètre `from` limité aux chemins internes (CWE-601). |
| **CODE** | Lints stricts, pipeline DevSecOps (OSV-Scanner, TruffleHog, SonarCloud, CodeQL), aucun secret commité. |
| **RESILIENCE** | Obfuscation et détection root / émulateur avant la mise en production. |
| **PRIVACY** | Logs réseau uniquement en dev, avec masquage des clés sensibles. Aucun en-tête ni formulaire multipart journalisé. Permissions Android minimales. Page de diagnostic déclarée uniquement en dev. |

## 9. Tests

- Chaque cas d'usage, repository et contrôleur a des tests unitaires.
- Les dépendances sont simulées avec `mocktail`.
- Les appels réseau sont testés avec un faux serveur (`HttpClientAdapter`).
- Le dossier `test/` reproduit exactement l'arborescence de `lib/`.

## 10. Workflow Git

1. Créer une branche : `feat/…`, `fix/…`, `security/…`, `chore/…`
2. Commits au format **Conventional Commits** :
   `feat(auth): add login page`
3. Avant chaque push :

```
   dart fix --apply
   dart format lib test
   flutter analyze
   flutter test
```

4. Ouvrir une **Pull Request** vers `main` : le pipeline doit être vert
   avant la fusion.

## 11. Ajouter une nouvelle fonctionnalité (checklist)

- [ ] `domain/entities/` : l'entité métier
- [ ] `domain/repositories/` : le contrat
- [ ] `domain/usecases/` : les actions métier
- [ ] `data/models/` : le DTO (freezed + json_serializable)
- [ ] `data/datasources/` : les appels API, via `guardApiCall()`
- [ ] `data/repositories/` : l'implémentation du contrat
- [ ] `presentation/controllers/` : l'état Riverpod
- [ ] `presentation/pages/` et `widgets/` : l'interface
- [ ] Textes ajoutés dans les 3 fichiers ARB (FR / EN / AR)
- [ ] Nom de route dans `core/navigation/app_routes.dart`, route déclarée dans `app/router/app_router.dart`
- [ ] Tests dans `test/features/<nom>/`
- [ ] Vérification des règles de sécurité (section 8)

## Outils de développement (Diagnostic, Galerie)

Les outils de développement ne doivent jamais être livrés aux utilisateurs.

| Protection | Vérifiée | Effet |
|---|---|---|
| `kDevToolsEnabled` (`DEV_TOOLS` dans `config/*.json`) | À la compilation | Le code des outils est **retiré du binaire** en staging et en prod (tree shaking) |
| `flavor == Flavor.dev` | À l'exécution | Les routes et les boutons ne sont déclarés qu'en dev |

Règle unique : `devToolsVisible(flavor)` (`lib/core/config/dev_tools.dart`).
Tout nouvel outil de développement DOIT passer par cette règle.
