import 'package:flutter/widgets.dart';

/// Icônes d'AfriMarket : Phosphor Icons (licence MIT), intégrées à l'app.
///
/// Règle de la charte (ADR 0011) :
/// - [AppIcons] (style « regular ») au repos ;
/// - [AppIconsFill] (style « fill ») quand l'élément est actif : onglet
///   sélectionné, favori ajouté...
///
/// Aucune icône Material (`Icons.*`) dans l'interface.
///
/// Les icônes sont des constantes : en version publiée, Flutter ne garde
/// dans l'app que les icônes réellement utilisées.
///
/// Ajouter une icône : chercher son nom sur phosphoricons.com, puis son
/// code dans `@phosphor-icons/web` (`src/regular/style.css`) ; le même code
/// sert pour le style « fill ».
abstract final class AppIcons {
  static const _family = 'PhosphorRegular';

  /// Accueil, catégorie Logement.
  static const house = IconData(0xe2c2, fontFamily: _family);

  /// Favoris, notes.
  static const star = IconData(0xe46a, fontFamily: _family);

  /// Publier une annonce.
  static const plusCircle = IconData(0xe3d6, fontFamily: _family);

  /// Ajouter.
  static const plus = IconData(0xe3d4, fontFamily: _family);

  /// Messages.
  static const chatCircle = IconData(0xe168, fontFamily: _family);

  /// Notifications.
  static const bell = IconData(0xe0ce, fontFamily: _family);

  /// Recherche.
  static const magnifyingGlass = IconData(0xe30c, fontFamily: _family);

  /// Lieu, quartier.
  static const mapPin = IconData(0xe316, fontFamily: _family);

  /// Voir plus (miroir automatique en arabe).
  static const caretRight = IconData(
    0xe13a,
    fontFamily: _family,
    matchTextDirection: true,
  );

  /// Liste déroulante.
  static const caretDown = IconData(0xe136, fontFamily: _family);

  /// Vendeur vérifié.
  static const sealCheck = IconData(0xe606, fontFamily: _family);

  /// Afficher le mot de passe.
  static const eye = IconData(0xe220, fontFamily: _family);

  /// Masquer le mot de passe.
  static const eyeSlash = IconData(0xe224, fontFamily: _family);

  /// Photo en cours de chargement.
  static const image = IconData(0xe2ca, fontFamily: _family);

  /// Photo introuvable.
  static const imageBroken = IconData(0xe7a8, fontFamily: _family);

  /// Validé, sélectionné.
  static const check = IconData(0xe182, fontFamily: _family);

  /// Hors ligne.
  static const wifiSlash = IconData(0xe4f2, fontFamily: _family);

  /// Erreur.
  static const warningCircle = IconData(0xe4e2, fontFamily: _family);

  /// Réessayer.
  static const arrowClockwise = IconData(0xe036, fontFamily: _family);

  /// J'aime.
  static const heart = IconData(0xe2a8, fontFamily: _family);

  /// Partager.
  static const shareNetwork = IconData(0xe408, fontFamily: _family);

  /// Enregistrer.
  static const bookmarkSimple = IconData(0xe0ea, fontFamily: _family);

  /// Aucune annonce.
  static const package = IconData(0xe390, fontFamily: _family);

  /// Se déconnecter.
  static const signOut = IconData(0xe42a, fontFamily: _family);

  /// Catégorie Services, outils de développement.
  static const wrench = IconData(0xe5d4, fontFamily: _family);

  /// Galerie du design system (dev).
  static const palette = IconData(0xe6c8, fontFamily: _family);

  /// Serveur.
  static const cloud = IconData(0xe1aa, fontFamily: _family);

  /// Succès.
  static const checkCircle = IconData(0xe184, fontFamily: _family);

  /// Tester la connexion.
  static const broadcast = IconData(0xe0f2, fontFamily: _family);

  /// Catégorie Articles.
  static const shoppingBag = IconData(0xe416, fontFamily: _family);

  /// Catégorie Emploi.
  static const briefcase = IconData(0xe0ee, fontFamily: _family);

  /// Catégorie Transport.
  static const car = IconData(0xe112, fontFamily: _family);

  /// Catégorie Autres.
  static const megaphone = IconData(0xe324, fontFamily: _family);

  /// Contacter sur WhatsApp.
  static const whatsappLogo = IconData(0xe5d0, fontFamily: _family);

  /// Appeler.
  static const phone = IconData(0xe3b8, fontFamily: _family);

  /// Ajouter une photo.
  static const camera = IconData(0xe10e, fontFamily: _family);

  /// Profil.
  static const user = IconData(0xe4c2, fontFamily: _family);

  /// Menu ☰ du fil.
  static const list = IconData(0xe2f0, fontFamily: _family);

  /// Catégories.
  static const squaresFour = IconData(0xe464, fontFamily: _family);

  /// Paramètres.
  static const gear = IconData(0xe270, fontFamily: _family);

  /// Aide et support.
  static const question = IconData(0xe3e8, fontFamily: _family);

  /// Se connecter.
  static const signIn = IconData(0xe428, fontFamily: _family);

  /// Retour (miroir automatique en arabe).
  static const arrowLeft = IconData(
    0xe058,
    fontFamily: _family,
    matchTextDirection: true,
  );

  /// Plus d'options.
  static const dotsThree = IconData(0xe1fe, fontFamily: _family);

  /// Signaler une annonce.
  static const flag = IconData(0xe244, fontFamily: _family);

  /// Conseils de sécurité.
  static const shieldCheck = IconData(0xe40c, fontFamily: _family);

  /// Filtres du fil.
  static const fadersHorizontal = IconData(0xe22a, fontFamily: _family);
}

/// Versions pleines des icônes de [AppIcons] (état actif).
abstract final class AppIconsFill {
  static const _family = 'PhosphorFill';

  /// Version pleine de [AppIcons.house].
  static const house = IconData(0xe2c2, fontFamily: _family);

  /// Version pleine de [AppIcons.star].
  static const star = IconData(0xe46a, fontFamily: _family);

  /// Version pleine de [AppIcons.chatCircle].
  static const chatCircle = IconData(0xe168, fontFamily: _family);

  /// Version pleine de [AppIcons.bell].
  static const bell = IconData(0xe0ce, fontFamily: _family);

  /// Version pleine de [AppIcons.bookmarkSimple].
  static const bookmarkSimple = IconData(0xe0ea, fontFamily: _family);

  /// Version pleine de [AppIcons.heart].
  static const heart = IconData(0xe2a8, fontFamily: _family);

  /// Version pleine de [AppIcons.checkCircle].
  static const checkCircle = IconData(0xe184, fontFamily: _family);

  /// Version pleine de [AppIcons.warningCircle].
  static const warningCircle = IconData(0xe4e2, fontFamily: _family);

  /// Version pleine de [AppIcons.sealCheck].
  static const sealCheck = IconData(0xe606, fontFamily: _family);
}
