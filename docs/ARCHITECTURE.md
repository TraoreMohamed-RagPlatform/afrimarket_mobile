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
ou en production. Les fichiers `config/<env>.json` ne contiennent **que des valeurs
publiques** : jamais de clé, mot de passe ou secret.

La configuration **Firebase** (clé d'API, jeton de débogage App Check) est dans un
second fichier, **local et jamais committé** : `config/firebase.<env>.json`
(modèle : `config/firebase.example.json`, voir ADR 0010) :

```
flutter run --flavor dev -t lib/main_dev.dart \
  --dart-define-from-file=config/dev.json \
  --dart-define-from-file=config/firebase.dev.json
```

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
| **RESILIENCE (App Check)** | Connexion, inscription et contact accompagnés d'un jeton Firebase App Check à usage unique (Play Integrity / App Attest en production, fournisseur debug en dev et staging), envoyé **qu'à notre API** (ADR 0010). |
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

## Index des décisions (ADR)

| ADR | Décision |
|---|---|
| [0001](adr/0001-clean-architecture-feature-first.md) | Clean Architecture organisée par fonctionnalité |
| [0002](adr/0002-consultation-sans-compte.md) | Consultation sans compte, fermé par défaut |
| [0003](adr/0003-coquille-onglets-et-liens.md) | Coquille à onglets et adresses des liens de partage |
| [0004](adr/0004-riverpod-gestion-etat.md) | Riverpod pour la gestion d'état et l'injection |
| [0005](adr/0005-couche-reseau-et-tokens.md) | Couche réseau, erreurs et tokens |
| [0006](adr/0006-traductions-fr-en-ar.md) | Traductions français, anglais, arabe |
| [0007](adr/0007-design-system.md) | Design system AfriMarket |
| [0008](adr/0008-outils-dev-hors-production.md) | Outils de dev retirés du binaire de production |
| [0009](adr/0009-textes-utilisateur-bidi.md) | Affichage des textes saisis par les utilisateurs |
| [0010](adr/0010-app-check-anti-robots.md) | App Check : preuve anti-robots sur les routes sensibles |
| [0011](adr/0011-identite-visuelle.md) | Identité visuelle : logo, police, icônes, démarrage animé |

## Éléments ajoutés en phase F2

| Emplacement | Contenu |
|---|---|
| `lib/core/theme/` | Tokens : palette, couleurs sémantiques, espacements, arrondis, typographie, animations, thème clair et sombre, calcul du contraste |
| `lib/core/navigation/route_access.dart` | Table d'accès des pages (`public`, `signInPrompt`, `authenticated`) |
| `lib/core/config/dev_tools.dart` | Règle unique des outils de dev (`devToolsVisible`) |
| `lib/app/shell/` | Coquille à onglets (`AppShell`) |
| `lib/app/dev/` | Galerie du design system (dev uniquement) |
| `lib/shared/widgets/` | Widgets partagés : cartes et grille d'annonces, en-tête, pastilles, barre du bas, champs, avatars, états (vide, erreur, chargement)... |
| `lib/shared/formatters/` | Prix, notes, textes utilisateur (`userText`) |
| `lib/shared/extensions/` | `context.l10n`, `context.colors`, `context.textStyles`, messages de confirmation |
| `test/helpers/` | Outils de test : `localizedApp`, `pumpAfriMarketApp` |

## Éléments ajoutés en phase F3 (authentification)

| Emplacement | Contenu |
|---|---|
| `lib/features/auth/domain/` | `AuthUser`, contrat `AuthRepository`, cas d'usage (connexion, inscription, mot de passe oublié, déconnexion), règles de saisie `AuthValidators` alignées sur le serveur (8 caractères minimum, 72 octets maximum) |
| `lib/features/auth/data/` | `AuthRemoteDataSource` (`/api/auth/*`), `AuthSessionModel` (JSON validé, tokens jamais affichés), `AuthRepositoryImpl` (tokens enregistrés dans le stockage chiffré, anti-énumération) |
| `lib/features/auth/presentation/` | Écrans connexion, inscription et mot de passe oublié (code à 6 chiffres), contrôleurs Riverpod, déconnexion complète `signOutProvider` |
| `lib/core/navigation/` | Routes `/register` et `/forgot-password` (publiques), paramètre `from` conservé entre connexion et inscription |
| `test/helpers/auth_page_harness.dart` | Ouvre un écran d'authentification dans un vrai routeur pour les tests |

Parcours :

- **Connexion / inscription** : la session s'ouvre, puis le routeur ramène
  l'utilisateur à la page demandée (`from`, chemin interne uniquement).
- **Mot de passe oublié** : même réponse que le compte existe ou non ; après
  le changement, le serveur ferme toutes les sessions et l'utilisateur se
  reconnecte.
- **Déconnexion** : les pages protégées sont masquées, la session locale est
  effacée, puis le serveur révoque le jeton (au mieux, même hors ligne).

## Éléments ajoutés en phase F4 (fil d'annonces)

| Emplacement | Contenu |
|---|---|
| `lib/features/listings/domain/` | `ListingSummary` (badge « Récent » < 24 h), `ListingPage`, `ListingCategory`, contrat `ListingsRepository`, cas d'usage `GetFeedUseCase`, `GetCategoriesUseCase` |
| `lib/features/listings/data/` | `ListingsRemoteDataSource` (`GET /api/listings`, `GET /api/filters`), modèles JSON validés : annonce mal formée ignorée, identifiant sûr pour une adresse, photos http(s) uniquement (adresse relative complétée avec le serveur) |
| `lib/features/listings/presentation/` | `FeedController` (première page, défilement infini, actualisation, catégorie ; réponses tardives ignorées), `HomePage`, menu ☰ `HomeDrawer`, liste des catégories `CategorySheet` |
| `lib/shared/widgets/app_sliver_header.dart` | `titleWidget` : le logo à la place du texte, le titre reste annoncé |
| `lib/core/navigation/` | `/profile` (connexion requise), `/settings` et `/help` (publics) |
| `lib/features/{search,profile,settings,support}/` | Pages provisoires « … arrive bientôt », atteignables depuis le fil |
| `test/helpers/fake_listings_repository.dart` | Faux dépôt d'annonces : aucun test n'appelle le vrai serveur |

Comportement du fil :

- **Premier chargement** : squelettes ; erreur plein écran avec « Réessayer ».
- **Défilement infini** : la page suivante (20 annonces) est demandée à
  600 px du bas ; une erreur s'affiche en bas sans masquer le fil.
- **Tirer pour actualiser** : les annonces restent visibles ; un échec est
  signalé par un message.
- **Fil vide** : invitation à publier (ou à voir toutes les annonces quand
  une catégorie est choisie).
- **Lieu (« Maârif · 5 km »)** : pas encore affiché, l'API des annonces n'a
  pas de champ de localisation.

## Identité visuelle (ADR 0011)

| Emplacement | Contenu |
|---|---|
| `lib/core/theme/app_icons.dart` | Icônes Phosphor : `AppIcons` (au repos), `AppIconsFill` (actif) |
| `lib/core/theme/app_logo_colors.dart` | Couleurs du logo selon le thème |
| `lib/shared/widgets/app_logo.dart` | `AppLogo` (logo horizontal), `AppLogoMark` (symbole), dessin `AppLogoPainter` |
| `lib/shared/widgets/app_logo_intro.dart` | Animation du logo (1,2 s) |
| `lib/shared/widgets/bogolan_strip.dart` | Motif signature |
| `lib/app/pages/splash_page.dart`, `lib/app/router/splash_intro.dart` | Écran de démarrage animé ; le routeur attend la fin de l'animation |
| `lib/app/font_licenses.dart` | Licences des polices dans la page « Licences » |
| `assets/fonts/` | Bricolage Grotesque (OFL), Phosphor (MIT) |
| `android/app/src/{main,dev,staging}/res`, `ios/Runner/Assets.xcassets`, `web/` | Icônes de l'app (pastille DEV / STG), écrans de lancement natifs |

Règles de travail : voir [Definition of Done](DEFINITION_OF_DONE.md).

## Éléments ajoutés en phase F5 (détail d'une annonce)

| Emplacement | Contenu |
|---|---|
| `lib/features/listings/domain/` | `ListingDetail`, `ListingSeller` (jamais de numéro), `SellerContact`, `ListingLocations`, `ReportReason` ; cas d'usage détail, similaires, lieux, contact, signalement (détail nettoyé et limité à 500 caractères) |
| `lib/features/listings/data/` | `GET /api/listings/:id`, `/similar`, `/contact`, `POST /report` (409 = déjà signalé, réussi), lieux de `GET /api/filters` ; `ListingJson` (lecture prudente commune au fil et au détail) ; numéro réduit à des chiffres avant toute adresse `tel:` ou `wa.me` |
| `lib/features/favorites/` | Contrat `FavoritesRepository` et `/api/favorites` (déjà enregistrée ou déjà retirée = réussi) |
| `lib/features/messaging/` | `MessageSellerUseCase` : conversation créée si besoin, puis message (vide ou > 1 000 caractères refusé sans appel) |
| `lib/core/platform/external_actions.dart` | Composeur, WhatsApp et partage derrière une interface (`ExternalActions`) : les tests n'ouvrent jamais d'application |
| `lib/features/listings/presentation/` | `ListingDetailPage` et ses widgets (photos, message, vendeur, détails, signalement), `FavoriteController` (affichage optimiste, rétabli en cas d'échec) |
| `lib/shared/` | Badges « Négociable » et « Vendu », `formatListingAge` (« il y a 2 h », « hier », date au-delà d'un mois) |
| `test/helpers/` | `FakeHttpServer` (Dio), faux favoris, messagerie et actions externes, annonce et vendeur de démonstration |

Comportement de la page :

- **Publique** (ADR 0002) ; écrire, appeler, WhatsApp, enregistrer et signaler
  demandent une connexion, puis ramènent à l'annonce.
- **Numéro du vendeur** : demandé seulement au moment d'appeler, jamais
  conservé ; boutons affichés seulement si le vendeur le partage.
- **Article vendu** : photos en noir et blanc, badge « Vendu », ni message ni
  appel.
- **Introuvable** : invitation à voir d'autres annonces ; **erreur** : message
  et « Réessayer » ; **chargement** : squelette avec le bouton retour.
- **Lieu** : nom du quartier lu dans la liste fixe du serveur ; jamais
  l'identifiant brut.
- **Limites connues** : le partage envoie un texte (titre et prix) en
  attendant les liens vérifiés (backlog C3) ; la conversation créée n'est pas
  encore rattachée à l'annonce côté serveur.


## Éléments ajoutés en phase B (filtres du fil, réservé, non-lus)

| Emplacement | Contenu |
|---|---|
| `lib/features/listings/domain/` | `FeedFilters` (ville, quartier, tri, prix min et max) et `FeedSort` (mêmes valeurs que le serveur) ; prix incohérents ignorés par `GetFeedUseCase` ; `isReserved` sur les annonces ; `ListingCategory.slug` et `icon` |
| `lib/features/listings/data/` | `GET /api/listings` reçoit `city`, `district`, `sort` (absent pour « plus récentes »), `minPrice`, `maxPrice` ; statut `RESERVED` lu, `SOLD` compris comme vendu ; identifiant et icône de catégorie acceptés seulement s'ils sont sûrs |
| `lib/features/listings/presentation/` | `FeedController.applyFilters` / `clearFilters` (catégorie et filtres indépendants), feuille « Filtres », icônes de catégorie (`categoryIcon`, liste fermée), `listingCardStatusOf` (« Vendu » l'emporte sur « Réservé ») |
| `lib/features/inbox/` | `UnreadCounts`, `GET /api/messages/unread-count` et `/api/notifications/unread-count` (en parallèle, plafonnés), `UnreadCountsController` |
| `lib/app/shell/app_shell.dart` | Pastilles sur Notifications et Messages ; relues toutes les minutes, au retour dans l'app et à chaque changement d'onglet |
| `test/helpers/` | `FakeUnreadCountsRepository`, filtres mémorisés par le faux dépôt d'annonces |

Comportement :

- **Fil** : pastilles « Vendre · Pour vous · Catégories ▾ · Filtres ▾ ». La
  pastille « Filtres » prend le nom du quartier quand c'est le seul filtre,
  sinon « Filtres · n ». « Pour vous » retire catégorie et filtres.
- **Feuille « Filtres »** : quartier (« Tout Casablanca » puis la liste du
  serveur), tri, prix ; rien n'est appliqué avant « Afficher les annonces » ;
  maximum inférieur au minimum = message et bouton inactif.
- **Fil vide filtré** : « Aucune annonce avec ces filtres », puis « Voir
  toutes les annonces ».
- **Réservé** : badge sur les cartes (fil, annonces similaires) et sur la page
  de détail, avec une explication ; écrire au vendeur reste possible.
- **Non-lus** : visiteur = aucune pastille et aucun appel ; un échec garde les
  derniers compteurs ; déconnexion = retour à zéro. « 99+ » au-delà de 99.
- **Limites connues** : une seule ville (Casablanca) proposée dans les
  filtres ; les compteurs ne sont pas encore poussés en temps réel
  (Socket.io, backlog S5).

## Éléments ajoutés : écran « Publier »

| Emplacement | Contenu |
|---|---|
| `lib/features/listings/domain/` | `ListingDraft` (saisie, limites du serveur, `problems`), `LocalPhoto`, contrat `ListingPublisher`, `PublishListingUseCase` |
| `lib/features/listings/data/repositories/listing_publisher_impl.dart` | `POST /api/listings` (statut `INACTIVE`), `POST /:id/images` (multipart `images`, noms de fichiers neutres, délai de 90 s), `PUT /:id` (`ACTIVE`), `DELETE /:id` |
| `lib/core/platform/photo_picker.dart` | `PhotoPicker` (galerie, appareil photo) derrière une interface ; photos réduites à 1600 px et recompressées sur le téléphone, métadonnées non demandées |
| `lib/features/listings/presentation/` | `PublishController` (libéré à la fermeture), `PublishListingPage` |
| `ios/Runner/Info.plist` | Textes d'autorisation : appareil photo, photos |
| `test/helpers/fake_publish.dart` | `FakeListingPublisher`, `FakePhotoPicker` |

Parcours (une seule page, comme Facebook Marketplace) :

- **Photos** (1 à 10) en haut ; la première est la photo principale ; toucher
  une vignette : « Mettre en photo principale » ou « Retirer ».
- Titre, prix (0 = gratuit), catégorie, quartier (obligatoire), état,
  description, négociable, remise.
- Les champs à compléter ne sont signalés qu'après un premier « Publier ».
- **Publication** : annonce créée masquée → photos envoyées → mise en ligne.
  Une étape échoue : l'annonce masquée est supprimée, la saisie reste à
  l'écran avec un message. Réussite : ouverture de l'annonce, fil actualisé.
- **Quitter** avec une saisie en cours : confirmation « Abandonner cette
  annonce ? ».
- **Limite connue** : pas encore de brouillon (backlog C1) ; une seule ville
  (Casablanca).

## Corrections après le premier essai sur émulateur

- **Retour après connexion** (`features/auth/presentation/sign_in_navigation.dart`) :
  quand une page protégée est ouverte PAR-DESSUS une autre (« Publier »,
  « Mon profil »), la redirection du routeur ne concerne que la page du
  dessous ; l'écran de connexion (ou d'inscription) se ferme donc lui-même
  vers la page demandée. `safeInternalPath` est désormais dans
  `core/navigation/`.
- **Votre annonce** : le serveur indique `isOwner` ; la page de détail
  affiche alors « C'est votre annonce » (réserver / remettre en vente,
  marquer comme vendue) au lieu d'« Écrire au vendeur », et sans
  « Enregistrer » ni « Signaler ».
- **Pastilles de choix** : fond gris clair (thème), visibles avant d'être
  choisies.
- **Quartiers** : tri et recherche sans accents ni majuscules
  (`core/text/text_fold.dart`).

## Temps réel (Socket.io)

| Emplacement | Contenu |
|---|---|
| `lib/core/realtime/realtime_connection.dart` | `RealtimeConnection` (interface) et `SocketIoRealtimeConnection` : jeton dans `auth` (jamais dans l'adresse), WebSocket seul, pas de reconnexion automatique avec un vieux jeton, événements connus seulement (`notification:new`, `message:new`) |
| `lib/features/inbox/presentation/realtime_controller.dart` | Connexion ouverte tant que la personne est connectée et l'app au premier plan ; événement reçu → compteurs relus ; fermée par le serveur → nouvel essai (2 s, 10 s, 30 s, 1 min) après relecture des compteurs (jeton renouvelé) |
| `lib/app/shell/app_shell.dart` | Démarre / met en pause / reprend / arrête la connexion avec la barre du bas et le cycle de vie de l'app ; relecture toutes les minutes gardée en secours |
| `test/helpers/fake_realtime_connection.dart` | Fausse connexion (événements et fermetures envoyés par le test) |

Le serveur n'envoie un événement qu'à son destinataire et refuse toute
connexion sans jeton valide (backend : `security/socket-auth`).
