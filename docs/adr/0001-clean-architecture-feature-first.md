# ADR 0001 — Clean Architecture organisée par fonctionnalité

- **Date :** 2026-09-28
- **Statut :** Acceptée
- **Auteur :** Traoré Mohamed

## Contexte

AfriMarket Mobile est une marketplace destinée à la communauté subsaharienne
au Maroc. L'application doit :

- **durer dans le temps** et pouvoir grossir fortement (12 modules métier dès
  le départ : authentification, annonces, recherche, favoris, messagerie,
  notifications, profil, évaluations, vérification KYC, support, paramètres) ;
- manipuler des **données sensibles** (tokens JWT, messages privés, documents
  d'identité) : la sécurité doit être intégrée dès la conception ;
- rester **cohérente** : chaque fonctionnalité doit être construite de la même
  manière, quel que soit le développeur ;
- être **testable** automatiquement dans le pipeline CI/CD DevSecOps.

## Décision

Nous adoptons la **Clean Architecture**, organisée **par fonctionnalité**
(*feature-first*).

1. Chaque fonctionnalité (`lib/features/<nom>/`) est découpée en trois couches :
    - `domain/` : entités, contrats de repositories, cas d'usage. Dart pur,
      sans aucune dépendance à Flutter, Dio ou au backend.
    - `data/` : sources de données (API), modèles DTO, implémentation des
      repositories.
    - `presentation/` : pages, widgets et contrôleurs d'état (Riverpod).
2. **Règle de dépendance :** `presentation → domain ← data`. Le domaine ne
   dépend de rien.
3. Le code technique transverse est placé dans `lib/core/`, et les composants
   d'interface partagés dans `lib/shared/`.
4. Outillage retenu : **Riverpod** (état + injection de dépendances),
   **go_router** (navigation), **Dio** (HTTP), **freezed / json_serializable**
   (modèles immuables), **flutter_secure_storage** (secrets).

## Alternatives considérées

| Alternative | Raison du rejet |
|---|---|
| Organisation par type (`screens/`, `services/`, `models/`) | Devient illisible au-delà de quelques écrans : le code d'une même fonctionnalité est dispersé dans tout le projet |
| MVC / MVVM sans couche domaine | La logique métier finit mélangée à l'interface ou aux appels API, ce qui rend les tests et les évolutions coûteux |
| BLoC pour la gestion d'état | Solide mais plus verbeux ; Riverpod offre la même testabilité avec moins de code et gère aussi l'injection de dépendances |

## Conséquences

**Positives**
- Chaque fonctionnalité est isolée : on peut la modifier ou la supprimer sans
  effet de bord sur les autres.
- Le domaine est testable sans émulateur ni réseau.
- Un changement d'API backend n'impacte que la couche `data`.
- Structure identique pour toutes les fonctionnalités, donc prise en main rapide.

**Négatives (acceptées)**
- Plus de fichiers et de code au démarrage d'une fonctionnalité.
- Courbe d'apprentissage des concepts (repositories, cas d'usage, Result).
- Génération de code (`build_runner`) à relancer après modification des modèles.