/// Texte « replié » pour trier et chercher sans tenir compte des accents,
/// des majuscules ni des apostrophes typographiques :
/// « Aïn Chock » → « ain chock », « Ben M’Sick » → « ben m'sick ».
///
/// Dart pur : utilisable dans le domaine.
String foldText(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_folded[char] ?? char);
  }
  return buffer.toString().trim();
}

/// Ordre alphabétique sans accents ni majuscules (« Aïn » avant « Anfa »).
int compareFolded(String a, String b) {
  final byFold = foldText(a).compareTo(foldText(b));
  return byFold != 0 ? byFold : a.compareTo(b);
}

const _folded = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'œ': 'oe',
  'æ': 'ae',
  '’': "'",
  '‘': "'",
  'ʼ': "'",
};
