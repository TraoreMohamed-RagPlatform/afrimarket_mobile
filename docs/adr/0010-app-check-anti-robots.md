# ADR 0010 — Firebase App Check pour prouver que les requêtes viennent de l'application

- **Statut** : accepté
- **Date de la décision** : 2026-10-11 (phase F3)

## Contexte

Le backend exige une preuve « anti-robots » avant la connexion,
l'inscription et le formulaire de contact. Le site web utilise reCAPTCHA
v3, mais une application mobile ne peut pas afficher reCAPTCHA
correctement. Sans preuve, le backend répond 403.

## Décision

- **Firebase App Check** fournit la preuve côté mobile :
  - production : **Play Integrity** (Android) et **App Attest** avec repli
    DeviceCheck (iOS) ;
  - dev et staging : fournisseur **debug** (émulateur, installation hors
    Play Store), avec un jeton de débogage déclaré dans la console Firebase.
- Le jeton est **à usage unique** (`getLimitedUseToken`) : le backend le
  « consomme » et refuse un rejeu.
- `AppCheckInterceptor` l'ajoute dans l'en-tête `X-Firebase-AppCheck`,
  **uniquement** vers notre API et sur `ApiEndpoints.attestedRoutes`.
- Le reste de l'application dépend de l'interface `AppAttestation`, pas de
  Firebase (tests avec une fausse implémentation).
- Firebase est initialisé **en Dart** à partir de
  `config/firebase.<environnement>.json` (fichier local, jamais committé),
  sans le plugin Gradle `google-services` : pas de fichier natif à
  fournir à la CI, et aucune clé dans le dépôt public.
- Fermé par défaut : configuration Firebase obligatoire en staging et en
  production (l'application refuse de démarrer sans) ; jeton de débogage
  interdit en production. En dev, Firebase peut être absent : la connexion
  est alors refusée par le serveur.

## Alternatives envisagées

| Option | Raison du rejet |
|---|---|
| reCAPTCHA dans une WebView | Expérience médiocre, plus facile à contourner |
| Pas de preuve sur mobile | Connexion et inscription exposées aux robots |
| Plugin Gradle `google-services` | Fichier natif à fournir à la CI ; clé d'API dans un fichier qui pourrait être committé par erreur |

## Conséquences

- Pour lancer l'application : un second fichier de configuration,
  `--dart-define-from-file=config/firebase.<environnement>.json`
  (voir `config/firebase.example.json`).
- Au premier lancement en dev, ajouter le jeton de débogage affiché dans
  les logs (« Enter this debug secret ») dans la console Firebase :
  App Check → Applications → ⋮ → Gérer les jetons de débogage. Le noter
  ensuite dans `APP_CHECK_DEBUG_TOKEN` pour qu'il reste stable.
- Avant la publication : lier le projet Firebase au Play Console pour
  Play Integrity.
