# ADR 0006 — Traductions français, anglais, arabe

- **Statut** : accepté
- **Date de la décision** : 2026-09-29 (phase F1.8) — rédigé le 2026-10-06

## Contexte

La communauté visée (subsaharienne, au Maroc) lit le français,
l'anglais ou l'arabe. L'arabe impose une mise en page de droite à
gauche. Les annonces sont écrites librement par les utilisateurs, dans
la langue de leur choix.

## Décision

- **gen-l10n** officiel de Flutter, fichiers ARB dans
  `lib/core/l10n/arb/`, modèle en français (`app_fr.arb`) ; chaque texte
  a une description (`required-resource-attributes`).
- Langue par défaut : celle du téléphone ; choix manuel prévu dans les
  Paramètres (`LocaleNotifier`, `null` = langue du téléphone).
- Droite à gauche automatique en arabe ; mise en page en
  `start` / `end`, jamais `left` / `right`.
- **Pluriels** ICU, dont les 6 formes de l'arabe.
- **Prix et notes** : chiffres occidentaux, y compris en arabe (usage
  marocain) ; devise traduite : DH (fr), MAD (en), د.م. (ar).
- Un test vérifie que les 3 fichiers ARB ont les mêmes clés et les mêmes
  paramètres : un oubli bloque le pipeline.

## Alternatives envisagées

| Option | Raison du rejet |
|---|---|
| `easy_localization` / packages tiers | Dépendance de plus ; gen-l10n est l'outil officiel, typé à la compilation |
| Chiffres arabes orientaux (١٢٣) | Inhabituels au Maroc pour les prix |

## Conséquences

- Tout nouveau texte est ajouté dans les 3 fichiers ARB
  (Definition of Done).
- Les textes saisis par les utilisateurs suivent une règle dédiée
  (isolation bidirectionnelle, ADR 0009).