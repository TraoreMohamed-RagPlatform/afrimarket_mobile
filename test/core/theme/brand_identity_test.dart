import 'dart:io';

import 'package:afrimarket_mobile/core/theme/app_icons.dart';
import 'package:afrimarket_mobile/core/theme/app_theme.dart';
import 'package:afrimarket_mobile/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Règles de la charte AfriMarket vérifiées automatiquement (ADR 0011).
void main() {
  group('Icônes Phosphor', () {
    test('aucune icône Material dans le code de l’app', () {
      final offenders = <String>[];
      final materialIcon = RegExp(r'(?<![A-Za-z])Icons\.[a-z]');
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (materialIcon.hasMatch(lines[i])) {
            offenders.add('${entity.path}:${i + 1}');
          }
        }
      }

      expect(offenders, isEmpty, reason: 'Utiliser AppIcons / AppIconsFill.');
    });

    test('regular au repos, fill quand actif : même dessin, deux polices', () {
      expect(AppIcons.house.fontFamily, 'PhosphorRegular');
      expect(AppIconsFill.house.fontFamily, 'PhosphorFill');
      expect(AppIcons.house.codePoint, AppIconsFill.house.codePoint);
    });

    test('les flèches se retournent en arabe', () {
      expect(AppIcons.caretRight.matchTextDirection, isTrue);
    });

    test('polices déclarées dans pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      for (final family in [
        'PhosphorRegular',
        'PhosphorFill',
        AppTypography.brandFamily,
      ]) {
        expect(pubspec, contains('family: $family'), reason: family);
      }
      for (final asset in [
        'assets/fonts/phosphor/Phosphor.ttf',
        'assets/fonts/phosphor/Phosphor-Fill.ttf',
        'assets/fonts/bricolage/BricolageGrotesque-600.ttf',
        'assets/fonts/bricolage/BricolageGrotesque-800.ttf',
      ]) {
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }
    });
  });

  for (final (name, theme) in [
    ('clair', AppTheme.light()),
    ('sombre', AppTheme.dark()),
  ]) {
    group('Thème $name', () {
      test('Bricolage pour titres, prix et boutons ; système ailleurs', () {
        final text = theme.textTheme;
        for (final style in [
          text.displaySmall,
          text.headlineSmall,
          text.titleLarge,
          text.titleMedium,
          text.labelLarge,
        ]) {
          expect(style?.fontFamily, AppTypography.brandFamily);
        }
        for (final style in [text.bodyLarge, text.bodyMedium, text.bodySmall]) {
          expect(style?.fontFamily, isNot(AppTypography.brandFamily));
        }
      });

      test('prix en chiffres de même largeur', () {
        expect(
          theme.textTheme.titleMedium?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      });

      test('aucune ombre portée', () {
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.cardTheme.elevation, 0);
        expect(theme.navigationBarTheme.elevation, 0);
        expect(theme.dialogTheme.elevation, 0);
        expect(theme.bottomSheetTheme.elevation, 0);
        expect(theme.bottomSheetTheme.modalElevation, 0);
        expect(theme.popupMenuTheme.elevation, 0);
        expect(theme.snackBarTheme.elevation, 0);
        expect(theme.floatingActionButtonTheme.elevation, 0);
      });
    });
  }
}
