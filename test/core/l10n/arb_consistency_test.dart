import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _arbDir = 'lib/core/l10n/arb';
const _template = 'fr';
const _translations = ['en', 'ar'];

/// Lit un fichier ARB et renvoie uniquement les textes (sans métadonnées).
Map<String, String> _messages(String locale) {
  final file = File('$_arbDir/app_$locale.arb');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  return {
    for (final entry in json.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}

/// Noms des variables d'un texte : {appName}, {minutes}...
Set<String> _placeholders(String message) {
  return RegExp(r'\{(\w+)\}')
      .allMatches(message)
      .map((m) => m.group(1)!)
      .toSet();
}

void main() {
  final template = _messages(_template);

  group('Fichiers ARB', () {
    for (final locale in _translations) {
      test('$locale : mêmes clés que le français', () {
        final translation = _messages(locale);

        final missing = template.keys.toSet().difference(
          translation.keys.toSet(),
        );
        final extra = translation.keys.toSet().difference(
          template.keys.toSet(),
        );

        expect(missing, isEmpty, reason: 'Traductions manquantes : $missing');
        expect(extra, isEmpty, reason: 'Clés inconnues : $extra');
      });

      test('$locale : mêmes variables que le français', () {
        final translation = _messages(locale);

        for (final key in template.keys) {
          final expected = _placeholders(template[key]!);
          final actual = _placeholders(translation[key] ?? '');

          expect(
            actual,
            expected,
            reason: 'Variables différentes pour « $key »',
          );
        }
      });

      test('$locale : aucun texte vide', () {
        final empty = _messages(locale).entries
            .where((e) => e.value.trim().isEmpty)
            .map((e) => e.key);

        expect(empty, isEmpty, reason: 'Textes vides : $empty');
      });
    }
  });
}
