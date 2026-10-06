/// Caractères de contrôle bidirectionnels pouvant TROMPER l'affichage
/// (encastrements, forçages et isolations : U+202A à U+202E, U+2066 à
/// U+2069).
final RegExp _bidiControls = RegExp('[\u202A-\u202E\u2066-\u2069]');

/// First Strong Isolate / Pop Directional Isolate (Unicode UAX #9).
const String _fsi = '\u2068';
const String _pdi = '\u2069';

/// Supprime les caractères de contrôle bidirectionnels d'un texte.
///
/// Sécurité (CWE-451, « Trojan Source » CVE-2021-42574) : empêche un
/// utilisateur d'inverser l'affichage d'un titre ou d'un nom pour tromper
/// les autres (ex. faire apparaître « exe.pdf » à la place de « fdp.exe »).
///
/// À utiliser pour les libellés lus par les lecteurs d'écran.
String stripBidiControls(String text) => text.replaceAll(_bidiControls, '');

/// Prépare un texte SAISI PAR UN UTILISATEUR pour l'affichage.
///
/// 1. Supprime les caractères de contrôle bidirectionnels (sécurité).
/// 2. Isole le texte (FSI ... PDI) : il prend son propre sens d'écriture
///    d'après son contenu. Une annonce en français reste correctement
///    ponctuée dans l'app en arabe, et inversement.
///
/// Règle (Definition of Done) : tout titre, description, message ou nom
/// saisi par un utilisateur est affiché via cette fonction.
String userText(String text) => '$_fsi${stripBidiControls(text)}$_pdi';
