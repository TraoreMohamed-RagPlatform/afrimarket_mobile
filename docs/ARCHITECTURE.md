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
├── app/                  # MaterialApp, bootstrap, navigation
├── core/                 # Socle technique (aucune logique métier)
│   ├── config/           #   Environnements, flavors
│   ├── network/          #   Dio, intercepteurs, endpoints
│   ├── error/            #   Result, Failures, exceptions
│   ├── storage/          #   Stockage sécurisé
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
| `core` | Packages externes | `features/` |
| `shared` | `core/` | `features/` |

**Entre fonctionnalités :** une feature n'importe **jamais** le dossier `data/`
d'une autre feature. Si deux features partagent un besoin, il est remonté dans
`core/` ou `shared/`.

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

- La couche `data` transforme toute exception technique (réseau, JSON, HTTP)
  en `Failure` métier.
- Les repositories retournent un `Result<T>` : succès **ou** échec, jamais
  d'exception non gérée vers l'interface.
- Les messages d'erreur affichés sont traduits et **ne révèlent jamais**
  de détails techniques (pile d'appels, URL internes).

## 6. Environnements

| Flavor | Application ID | API | Usage |
|---|---|---|---|
| `dev` | `com.afrimarket.afrimarket_mobile.dev` | Backend local (HTTP autorisé en debug) | Développement |
| `staging` | `com.afrimarket.afrimarket_mobile.staging` | Serveur de test (HTTPS) | Recette |
| `prod` | `com.afrimarket.afrimarket_mobile` | Serveur de production (HTTPS) | Utilisateurs |

Aucune URL, clé ou secret n'est écrit en dur dans le code : la configuration
est injectée au build (`--dart-define`).

## 7. Internationalisation

- Langues : **français** (par défaut), **anglais**, **arabe**.
- Aucun texte affiché n'est écrit en dur : tout passe par les fichiers ARB.
- L'arabe s'affiche de **droite à gauche (RTL)** : utiliser
  `EdgeInsetsDirectional`, `AlignmentDirectional`, `start` / `end`,
  jamais `left` / `right`.

## 8. Sécurité (OWASP MASVS v2)

| Catégorie | Règle |
|---|---|
| **STORAGE** | Tokens et secrets uniquement dans `flutter_secure_storage`. Sauvegarde Android désactivée (`allowBackup="false"`). |
| **NETWORK** | HTTPS obligatoire en staging / prod. HTTP autorisé uniquement en debug vers le backend local (`network_security_config.xml`). |
| **AUTH** | Refresh automatique du token, un seul refresh simultané, déconnexion si le refresh échoue. |
| **CODE** | Lints stricts, pipeline DevSecOps (OSV-Scanner, TruffleHog, SonarCloud, CodeQL), aucun secret commité. |
| **RESILIENCE** | Obfuscation et détection root / émulateur avant la mise en production. |
| **PRIVACY** | Aucune donnée personnelle ni token dans les logs. Permissions Android minimales. |

## 9. Tests

- Chaque cas d'usage, repository et contrôleur a des tests unitaires.
- Les dépendances sont simulées avec `mocktail`.
- Le dossier `test/` reproduit exactement l'arborescence de `lib/`.

## 10. Workflow Git

1. Créer une branche : `feat/…`, `fix/…`, `security/…`, `chore/…`
2. Commits au format **Conventional Commits** :
   `feat(auth): add login page`
3. Avant chaque push :
```
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
- [ ] `data/datasources/` : les appels API
- [ ] `data/repositories/` : l'implémentation du contrat
- [ ] `presentation/controllers/` : l'état Riverpod
- [ ] `presentation/pages/` et `widgets/` : l'interface
- [ ] Textes ajoutés dans les 3 fichiers ARB (FR / EN / AR)
- [ ] Route ajoutée dans `app/router/`
- [ ] Tests dans `test/features/<nom>/`
- [ ] Vérification des règles de sécurité (section 8)