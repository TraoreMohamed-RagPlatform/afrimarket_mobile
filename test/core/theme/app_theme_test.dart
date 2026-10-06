import 'package:afrimarket_mobile/core/theme/app_colors.dart';
import 'package:afrimarket_mobile/core/theme/app_theme.dart';
import 'package:afrimarket_mobile/core/theme/theme_mode_provider.dart';
import 'package:afrimarket_mobile/shared/extensions/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('le thème clair utilise les couleurs claires', () {
      final theme = AppTheme.light();

      expect(theme.brightness, Brightness.light);
      expect(theme.extension<AppColors>(), AppColors.light);
      expect(theme.colorScheme.primary, AppColors.light.brand);
      expect(theme.scaffoldBackgroundColor, AppColors.light.background);
    });

    test('le thème sombre utilise les couleurs sombres', () {
      final theme = AppTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.extension<AppColors>(), AppColors.dark);
      expect(theme.colorScheme.primary, AppColors.dark.brand);
    });

    testWidgets('suit le mode sombre du téléphone', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      late AppColors colors;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              colors = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(colors, AppColors.dark);
    });
  });

  group('ThemeModeNotifier', () {
    test('suit le téléphone par défaut, puis change de mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);

      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });
}
