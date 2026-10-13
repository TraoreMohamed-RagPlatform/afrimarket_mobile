# ADR 0011 — Identité visuelle : logo, police, icônes, démarrage animé

- **Statut** : accepté
- **Date** : 2026-10-11

## Contexte

L'ergonomie suit Facebook Marketplace (ADR 0007), mais l'app ne doit pas
ressembler à une interface générique. Une charte a été validée : couleurs
inchangées (terre cuite et ambre), une police de marque, des icônes
cohérentes, un logo propre à AfriMarket et un écran de démarrage animé.

## Décision

### Logo
- Symbole : un chariot au trait, un aplat ambre décalé derrière le panier et
  un pagne wax plié, en terre cuite, avec un chevron crème.
- Trait noir (`#222220`) en clair, blanc en sombre ; le pagne et le nom
  « AfriMarket » ont toujours la même couleur (`#993C1D` en clair,
  `#D85A30` en sombre). Couleurs : `AppLogoColors`.
- Dessiné en code (`AppLogoPainter`) : net à toutes les tailles, coloré
  selon le thème, animable. Widgets : `AppLogo` (logo horizontal),
  `AppLogoMark` (symbole seul). Toujours de gauche à droite, même en arabe.
- Icône de l'app : symbole sur fond crème `#FFF6F0` ; Android adaptatif
  (zone sûre) et monochrome (Android 13) ; pastille DEV / STG pour les
  environnements de test (`android/app/src/dev|staging/res`).

### Écran de démarrage
- Écran natif (Android, iOS, web) : fond uni crème (sombre en mode sombre),
  sans logo. L'app dessine ensuite le logo animé sur le même fond : aucun
  saut entre l'écran natif et l'app.
- Animation de 1,2 s (`AppLogoIntro`) : le chariot se dessine, l'aplat se
  cale, le pagne tombe dans le panier, puis le nom se dévoile.
- Le routeur garde l'écran de démarrage jusqu'à la fin de l'animation
  (`splashIntroFinishedProvider`) ; la session est vérifiée en parallèle.
- « Réduire les animations » : logo complet affiché directement.

### Police
- **Bricolage Grotesque** (licence OFL), intégrée à l'app (pas de
  téléchargement au lancement) : graisses 600 et 800, caractères latins
  uniquement. Logo, titres, prix (chiffres de même largeur) et boutons.
- Police du système pour le reste ; l'arabe utilise toujours la police du
  système.

### Icônes
- **Phosphor** (licence MIT) : polices `PhosphorRegular` et `PhosphorFill`
  intégrées, constantes `AppIcons` (au repos) et `AppIconsFill` (actif).
- Aucune icône Material : un test le vérifie sur tout le dossier `lib/`.
- Constantes : en version publiée, Flutter ne garde que les icônes utilisées.

### Formes et motif
- Aucune ombre portée (thème : élévation 0 partout, testé).
- Motif bogolan original (`BogolanStrip`) seulement sur le démarrage,
  l'en-tête des écrans d'authentification et les écrans vides.

## Alternatives envisagées

| Option | Raison du rejet |
|---|---|
| Paquet `phosphor_flutter` | Incompatible avec Flutter 3.44 et plus (`IconData` est désormais `final`) |
| Logo en image (SVG / PNG) | Couleurs figées, pas d'animation, dépendance `flutter_svg` |
| Police téléchargée au lancement (`google_fonts`) | Réseau requis, vie privée, premier affichage instable |
| Logo sur l'écran natif d'Android 12 | Taille et position imposées : saut visible avant l'animation |

## Conséquences

- Les licences OFL et MIT sont affichées dans la page « Licences » de l'app
  (`FontLicenses`).
- Ajouter une icône : ajouter une constante dans `AppIcons` (code du
  caractère Phosphor), jamais `Icons.*`.
- Changer le logo : un seul fichier (`app_logo.dart`), puis régénérer les
  icônes de l'app.
