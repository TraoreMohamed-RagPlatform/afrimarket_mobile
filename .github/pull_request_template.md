## Résumé

<!-- Ce que fait cette Pull Request, en quelques lignes. -->

## Type de modification

- [ ] Nouvelle fonctionnalité (`feat`)
- [ ] Correction (`fix`)
- [ ] Sécurité (`security`)
- [ ] Documentation, configuration, outillage (`docs`, `chore`, `ci`)

## Captures (si l'interface change)

<!-- Mode clair et mode sombre ; arabe si la mise en page est concernée. -->

## Definition of Done

Détail et justification : [`docs/DEFINITION_OF_DONE.md`](../docs/DEFINITION_OF_DONE.md)

### Architecture et évolutivité
- [ ] Placement conforme à `docs/ARCHITECTURE.md`, règles de dépendance respectées
- [ ] Aucune fonctionnalité n'importe le dossier `data/` d'une autre
- [ ] Widgets partagés autonomes (sans `Scaffold` ni fonctionnalité supposés)
- [ ] Points d'extension prévus, sans fonctionnalité spéculative

### Qualité du code
- [ ] `dart fix`, `dart format`, `flutter analyze` : 0 remarque
- [ ] Aucun texte, couleur ou dimension en dur
- [ ] Erreurs gérées via `Result` / `Failure`
- [ ] API publique documentée

### Sécurité
- [ ] Aucun secret, aucune donnée personnelle ni token dans les logs
- [ ] Données externes validées
- [ ] Moindre privilège respecté

### Accessibilité et traductions
- [ ] Contraste WCAG AA, libellés pour lecteurs d'écran
- [ ] Zones tactiles ≥ 48 × 48, aucun débordement avec texte × 2
- [ ] Compatible droite à gauche
- [ ] Textes ajoutés dans les 3 fichiers ARB
- [ ] Textes saisis par les utilisateurs affichés via `userText()`

### Visuel
- [ ] Vérifié en mode clair et en mode sombre

### Tests
- [ ] Tests unitaires et de widgets ajoutés
- [ ] Arabe, mode sombre et grand texte couverts
- [ ] Cas limites couverts

### Documentation et Git
- [ ] `ARCHITECTURE.md` / ADR mis à jour si nécessaire
- [ ] Commits au format Conventional Commits