import 'dart:convert';

/// Problème détecté sur un champ d'un formulaire d'authentification.
///
/// La présentation choisit le message traduit correspondant.
enum AuthFieldIssue {
  empty,
  invalidEmail,
  passwordTooShort,
  passwordTooLong,
  passwordMismatch,
  usernameTooShort,
  usernameTooLong,
  usernameInvalid,
  nameTooLong,
  codeInvalid,
}

/// Règles de saisie, alignées sur celles du serveur.
///
/// Elles évitent un aller-retour inutile ; le serveur reste seul juge
/// (OWASP MASVS : toute validation côté client est contournable).
abstract final class AuthValidators {
  /// Longueur minimale d'un mot de passe (règle du serveur).
  static const passwordMinLength = 8;

  /// Limite technique de bcrypt : au-delà, les octets sont ignorés.
  static const passwordMaxBytes = 72;

  static const usernameMinLength = 3;
  static const usernameMaxLength = 30;
  static const fullNameMaxLength = 100;
  static const emailMaxLength = 254;
  static const codeLength = 6;

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _username = RegExp(r'^[A-Za-z0-9._-]+$');
  static final _code = RegExp(r'^\d{6}$');

  /// E-mail : obligatoire et de forme `nom@domaine.ext`.
  static AuthFieldIssue? email(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return AuthFieldIssue.empty;
    if (text.length > emailMaxLength || !_email.hasMatch(text)) {
      return AuthFieldIssue.invalidEmail;
    }
    return null;
  }

  /// Mot de passe existant (connexion) : seulement obligatoire.
  ///
  /// La règle de longueur ne s'applique qu'aux NOUVEAUX mots de passe :
  /// un ancien compte doit toujours pouvoir se connecter.
  static AuthFieldIssue? currentPassword(String? value) {
    return (value ?? '').isEmpty ? AuthFieldIssue.empty : null;
  }

  /// Nouveau mot de passe : 8 caractères minimum, 72 octets maximum.
  static AuthFieldIssue? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return AuthFieldIssue.empty;
    if (text.runes.length < passwordMinLength) {
      return AuthFieldIssue.passwordTooShort;
    }
    if (utf8.encode(text).length > passwordMaxBytes) {
      return AuthFieldIssue.passwordTooLong;
    }
    return null;
  }

  /// Confirmation : identique au mot de passe saisi.
  static AuthFieldIssue? confirmation(String? value, String password) {
    if ((value ?? '').isEmpty) return AuthFieldIssue.empty;
    return value == password ? null : AuthFieldIssue.passwordMismatch;
  }

  /// Nom d'utilisateur : 3 à 30 caractères, sans espace ni symbole.
  static AuthFieldIssue? username(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return AuthFieldIssue.empty;
    if (text.length < usernameMinLength) {
      return AuthFieldIssue.usernameTooShort;
    }
    if (text.length > usernameMaxLength) {
      return AuthFieldIssue.usernameTooLong;
    }
    if (!_username.hasMatch(text)) return AuthFieldIssue.usernameInvalid;
    return null;
  }

  /// Nom complet : obligatoire, 100 caractères maximum.
  static AuthFieldIssue? fullName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return AuthFieldIssue.empty;
    if (text.runes.length > fullNameMaxLength) {
      return AuthFieldIssue.nameTooLong;
    }
    return null;
  }

  /// Code de réinitialisation : exactement 6 chiffres.
  static AuthFieldIssue? resetCode(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return AuthFieldIssue.empty;
    return _code.hasMatch(text) ? null : AuthFieldIssue.codeInvalid;
  }
}
