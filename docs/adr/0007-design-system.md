# ADR 0007 — Design system AfriMarket

- **Statut** : accepté
- **Date** : 2026-10-03 (phase F2)

## Contexte

Les 19 pages doivent être cohérentes, accessibles, disponibles en clair
et en sombre, et en 3 langues. L'ergonomie s'inspire de Facebook
Marketplace (captures de référence), avec une identité propre : aucun
élément protégé de Meta (logo, bleu, icônes, nom).

## Décision

### Tokens
- **Palette brute** (`AppPalette`) et **couleurs sémantiques**
  (`AppColors`, `ThemeExtension`, clair + sombre). Les pages n'utilisent
  que les couleurs sémantiques.
- Couleur principale **terre cuite** `#993C1D`, accent ambre `#EF9F27`.
  En sombre : terre cuite claire avec texte foncé (Material 3).
- Espacements (multiples de 4), arrondis, typographie (police du
  système), durées d'animation (`AppMotion`, respect de « Réduire les
  animations »).

### Accessibilité vérifiée par les tests
- Contraste **WCAG 2.1 AA** (4,5:1) de chaque paire texte / fond, en
  clair et en sombre.
- Galerie contrôlée par les guides officiels de Flutter (zones tactiles
  48 × 48, libellés, contraste réellement affiché), en clair, sombre et
  arabe.

### Widgets partagés (`lib/shared/widgets/`)
- **Autonomes** : chacun fournit sa propre surface Material et ne dépend
  d'aucune fonctionnalité.
- **Points d'extension** prévus (badges, action, statut, onglets...),
  sans fonctionnalité spéculative (YAGNI).
- Mise en page mesurée, jamais estimée (ex. `ListingCard.textAreaHeight`).

### Galerie (`lib/app/dev/gallery_page.dart`)
- Documentation vivante de toutes les briques ; outil de dev retiré du
  binaire de production (ADR 0008).

## Alternatives envisagées

| Option | Raison du rejet |
|---|---|
| Police personnalisée | Intégration et poids supplémentaires ; reportée |
| Kit d'interface tiers | Identité moins maîtrisée, dépendance de plus |
| Widgetbook | Outil externe ; une page de galerie suffit à ce stade |

## Conséquences

- Tout nouveau widget partagé est ajouté à la galerie : il est alors
  contrôlé automatiquement.
- Tests visuels « golden » prévus une fois le design stabilisé, générés
  dans le pipeline (polices différentes entre Windows et Linux).