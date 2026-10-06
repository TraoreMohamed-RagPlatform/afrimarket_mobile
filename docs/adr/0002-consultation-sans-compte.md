# ADR 0002 — Consultation sans compte

- **Statut** : accepté
- **Date** : 2026-10-03

## Contexte

Jusqu'ici, tout visiteur non connecté était redirigé vers la page de
connexion. Exiger un compte avant même de voir une annonce est l'un des
freins les mieux documentés à l'adoption d'une application, en
particulier pour une marketplace où la découverte des annonces est le
premier usage. Les liens d'annonces partagés (WhatsApp notamment)
doivent aussi s'ouvrir directement.

## Décision

1. Le fil, la recherche, le détail d'une annonce et le profil public
   d'un vendeur sont **publics**.
2. La connexion n'est demandée qu'au moment d'**agir** (publier,
   contacter, enregistrer). Après connexion, l'utilisateur revient à la
   page demandée (paramètre `from`).
3. Les onglets personnels (Favoris, Messages, Notifications) s'ouvrent,
   mais affichent une **invitation à se connecter** au lieu du contenu.
4. Les règles sont centralisées dans `RouteAccessPolicy`, avec trois
   niveaux : `public`, `signInPrompt`, `authenticated`.
5. **Fermé par défaut** : toute page non déclarée est `authenticated`.

## Sécurité (OWASP MASVS - AUTH, CWE-601)

- Le principe « fermé par défaut » est conservé : oublier de déclarer une
  page la rend protégée, jamais publique.
- Les règles publiques sont des expressions régulières strictes : un
  identifiant mal formé ne correspond à aucune règle publique.
- La page mémorisée (`from`) passe toujours par `safeInternalPath` :
  aucune redirection vers un site externe.
- La protection côté application ne remplace pas celle du serveur : le
  backend doit exposer publiquement les seules routes de lecture
  (`GET /api/listings`, détail, profil public) et protéger tout le reste.

## Conséquences

- Démarrage sans compte : le fil, et non plus la page de connexion.
- Backend : les routes de lecture des annonces deviennent publiques
  (à traiter dans la phase de sécurisation du backend).
- Ajouter une page = ajouter une règle dans `RouteAccessPolicy`
  (sinon, elle est protégée).