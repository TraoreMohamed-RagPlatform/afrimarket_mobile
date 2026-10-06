# ADR 0003 — Coquille à onglets et adresses des liens de partage

- **Statut** : accepté
- **Date** : 2026-10-03

## Contexte

L'app s'organise autour d'une barre du bas validée : Accueil, Favoris,
Publier (action centrale), Messages, Notifications. Les annonces seront
partagées par lien (WhatsApp notamment), et ces liens doivent ouvrir
l'annonce directement dans l'app.

## Décision

### Coquille à onglets

- `StatefulShellRoute.indexedStack` (go_router) : chaque onglet garde sa
  propre pile de navigation et sa position de défilement.
- Toucher l'onglet actif ramène à sa première page.
- **Publier** est une action, pas un onglet : la route `/publish` est
  déclarée hors de la coquille et s'ouvre en plein écran.
- La barre (`AppBottomNavBar`) est un widget partagé générique ; la
  coquille (`AppShell`) lui fournit les onglets. L'ordre des onglets doit
  correspondre à l'ordre des branches du routeur.

### Adresses stables (liens de partage)

| Page | Adresse |
|---|---|
| Fil | `/` |
| Détail d'une annonce | `/listings/:id` |
| Profil public d'un vendeur | `/sellers/:id` |
| Recherche | `/search` |

Les identifiants sont encodés à la construction (`AppRoutes.listing`) et
validés par `RouteAccessPolicy` (1 à 64 caractères sûrs).

### Liens vérifiés (Android App Links) — reporté

Pour qu'un lien `https://<domaine>/listings/12` ouvre l'app, il faut des
**liens vérifiés** : sans vérification, une autre application pourrait
intercepter les liens AfriMarket.

Prérequis, à la charge du projet :

1. Acheter le nom de domaine (`.ma` recommandé, `.com` en protection).
2. Sécuriser le compte du registraire : double authentification,
   renouvellement automatique, verrouillage contre les transferts.
3. Publier `/.well-known/assetlinks.json` sur le domaine (empreinte de la
   clé de signature de l'app).
4. Déclarer le filtre d'intention `autoVerify` dans le manifeste Android.

## Conséquences

- Les adresses ci-dessus sont un contrat : les changer casserait les
  liens déjà partagés.
- Les étapes 3 et 4 seront réalisées dès que le domaine sera acheté.