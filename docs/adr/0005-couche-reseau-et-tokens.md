# ADR 0005 — Couche réseau, gestion des erreurs et des tokens

- **Statut** : accepté
- **Date de la décision** : 2026-09-28 (phases F1.4 à F1.6) — rédigé le 2026-10-06

## Contexte

L'application dialogue avec l'API AfriMarket (Node.js / Express) avec
des tokens JWT (accès + rafraîchissement). Il faut une couche réseau
sûre (OWASP MASVS NETWORK, AUTH, STORAGE, PRIVACY), dont les erreurs ne
plantent jamais l'interface et n'exposent aucun détail technique.

## Décision

### Erreurs
- `Failure` : classe scellée (11 cas), et `Result<T>` (`Ok` / `Err`).
- `guardApiCall()` transforme tout appel en `Result` ; `errorMapper`
  convertit les erreurs Dio en `Failure`.
- Le `switch` exhaustif oblige à traiter chaque cas, y compris les futurs.

### Client Dio
- Délais : 10 s (connexion), 15 s (envoi et réception) ;
  `followRedirects: false`.
- **Intercepteur d'authentification** : le token n'est envoyé qu'à
  l'API (même schéma, hôte et port), jamais aux routes publiques
  (`skipAuth`).
- **Rafraîchissement du token** : une seule requête de rafraîchissement
  à la fois (`Completer`), sans boucle (marqueur de nouvelle tentative),
  avec un client Dio séparé ; la session est conservée en cas d'erreur
  réseau ; prêt pour la rotation des tokens.
- **Journal** : en dev uniquement, données sensibles masquées (mot de
  passe, token, code, carte, IBAN...), en-têtes jamais journalisés.

### Stockage des tokens
- `flutter_secure_storage` : Keystore (Android), Keychain (iOS,
  `first_unlock_this_device`), jamais sauvegardés hors de l'appareil.
- Token d'accès en mémoire, token de rafraîchissement toujours relu du
  stockage ; enregistrement « tout ou rien » ; à la déconnexion, la
  mémoire est effacée avant le stockage.

## Alternatives envisagées

| Option | Raison du rejet |
|---|---|
| Package `http` | Pas d'intercepteurs ; retiré en F1.9b |
| Retrofit / Chopper | Génération de code ; Dio seul suffit à ce stade |
| `shared_preferences` pour les tokens | Non chiffré : contraire à MASVS STORAGE |

## Conséquences

- Les pages ne reçoivent que des `Failure`, affichées par un message
  traduit (`failure.message(l10n)`).
- Faiblesses du backend identifiées (tokens identiques, pas de rotation,
  messages d'erreur 500 détaillés...) : à corriger lors de la phase de
  sécurisation du backend, avant toute mise en production.