# ADR 0004 — Riverpod pour la gestion d'état et l'injection

- **Statut** : accepté
- **Date de la décision** : 2026-09-28 (phase F1) — rédigé le 2026-10-06

## Contexte

L'application va grandir (12 fonctionnalités prévues). Il faut une
solution unique pour l'état de l'interface ET l'injection des
dépendances (client réseau, stockage, cas d'usage), testable sans
appareil, et qui ne dépende pas de l'arbre des widgets.

## Décision

- **Riverpod 3** (`flutter_riverpod`) pour l'état et l'injection.
- `Notifier` / `NotifierProvider` pour les états modifiables
  (session, langue, mode d'affichage, contrôleurs de pages).
- `autoDispose` pour l'état propre à une page (libéré en la quittant).
- Injection centralisée par fonctionnalité dans
  `<feature>/<feature>_providers.dart` (data → domain).
- Tests : `ProviderContainer` et `overrides` pour remplacer une
  dépendance par une fausse (stockage, cas d'usage...).
- Pas de génération de code (`riverpod_generator`) à ce stade.

## Alternatives envisagées

| Option | Raison du rejet |
|---|---|
| Bloc | Plus de code répétitif (événements, états) pour le même résultat ; injection à gérer à part |
| Provider | Prédécesseur de Riverpod, dépend du `BuildContext`, moins sûr à la compilation |
| GetX | État global implicite, difficile à tester et à faire évoluer |
| `setState` seul | Insuffisant dès que l'état est partagé entre pages |

## Conséquences

- Toute dépendance est remplaçable dans les tests, sans modification du
  code de production.
- Les widgets dépendent des providers, jamais d'une implémentation
  concrète (règle de dépendance de la Clean Architecture).
- La génération de code pourra être adoptée plus tard si le nombre de
  providers le justifie (nouvel ADR).