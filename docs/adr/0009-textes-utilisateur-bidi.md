# ADR 0009 — Affichage des textes saisis par les utilisateurs

- **Statut** : accepté
- **Date** : 2026-10-06 (phase F2e)

## Contexte

Les utilisateurs écrivent leurs annonces, messages et noms dans la
langue de leur choix, souvent en français, alors que l'interface peut
être en arabe (et inversement). L'algorithme bidirectionnel Unicode
déplace alors la ponctuation (`!iPhone 11, très bon état`).

Par ailleurs, des caractères de contrôle invisibles (ex. `U+202E`)
permettent d'inverser l'affichage d'un texte pour tromper l'utilisateur :
attaques « Trojan Source » (CVE-2021-42574), CWE-451.

## Décision

- `userText()` (`lib/shared/formatters/user_text.dart`) :
  1. supprime les caractères de contrôle bidirectionnels
     (U+202A à U+202E, U+2066 à U+2069) ;
  2. isole le texte (`FSI` … `PDI`, Unicode UAX #9) : il prend son propre
     sens d'après son contenu.
- `stripBidiControls()` pour les libellés lus par les lecteurs d'écran.
- Règle de la Definition of Done : tout texte saisi par un utilisateur
  est affiché via `userText()`.

## Conséquences

- Ponctuation correcte quelle que soit la langue de l'interface.
- Un utilisateur ne peut pas déguiser un titre, un nom ou un lien.
- Le serveur reste responsable de la validation des données ; il est
  recommandé qu'il rejette aussi ces caractères à l'enregistrement
  (phase de sécurisation du backend).