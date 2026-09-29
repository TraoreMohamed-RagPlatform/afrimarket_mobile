import 'package:afrimarket_mobile/core/theme/app_colors.dart';
import 'package:afrimarket_mobile/core/theme/color_contrast.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paires texte / fond utilisées dans l'app.
Map<String, (Color, Color)> _textPairs(AppColors c) => {
  'texte principal / fond': (c.textPrimary, c.background),
  'texte principal / surface': (c.textPrimary, c.surface),
  'texte principal / surface grise': (c.textPrimary, c.surfaceMuted),
  'texte secondaire / fond': (c.textSecondary, c.background),
  'texte secondaire / surface': (c.textSecondary, c.surface),
  'texte sur bouton principal': (c.onBrand, c.brand),
  'texte de la pastille active': (c.onBrandSoft, c.brandSoft),
  'texte du badge': (c.onAccent, c.accent),
  'texte sur erreur': (c.onError, c.error),
  'lien de marque / fond': (c.brand, c.background),
};

void main() {
  group('contrastRatio', () {
    test('noir sur blanc = 21', () {
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01),
      );
    });

    test('une couleur sur elle-même = 1', () {
      expect(
        contrastRatio(const Color(0xFF993C1D), const Color(0xFF993C1D)),
        closeTo(1, 0.01),
      );
    });
  });

  for (final (mode, colors) in [
    ('clair', AppColors.light),
    ('sombre', AppColors.dark),
  ]) {
    group('Accessibilité WCAG 2.1 AA - mode $mode', () {
      for (final MapEntry(key: name, value: (text, bg)) in _textPairs(
        colors,
      ).entries) {
        test(name, () {
          final ratio = contrastRatio(text, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(wcagAaNormalText),
            reason: 'Contraste insuffisant : ${ratio.toStringAsFixed(2)}:1',
          );
        });
      }
    });
  }

  group('AppColors', () {
    test('la couleur de marque en clair est la terre cuite #993C1D', () {
      expect(AppColors.light.brand, const Color(0xFF993C1D));
    });

    test('copyWith ne modifie que la couleur demandée', () {
      final copy = AppColors.light.copyWith(brand: const Color(0xFF000000));

      expect(copy.brand, const Color(0xFF000000));
      expect(copy.background, AppColors.light.background);
    });

    test('lerp aux extrémités donne le clair puis le sombre', () {
      expect(
        AppColors.light.lerp(AppColors.dark, 0).brand,
        AppColors.light.brand,
      );
      expect(
        AppColors.light.lerp(AppColors.dark, 1).brand,
        AppColors.dark.brand,
      );
    });
  });
}
