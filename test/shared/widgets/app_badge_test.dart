import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/shared/widgets/app_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

void main() {
  final ar = lookupAppLocalizations(const Locale('ar'));

  testWidgets('badge Récent', (tester) async {
    await tester.pumpWidget(localizedApp(const AppBadge(AppBadgeType.recent)));

    expect(find.text(fr.badgeRecent), findsOneWidget);
  });

  testWidgets('badge Vérifié avec son icône', (tester) async {
    await tester.pumpWidget(
      localizedApp(const AppBadge(AppBadgeType.verified)),
    );

    expect(find.text(fr.badgeVerified), findsOneWidget);
    expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
  });

  testWidgets('fonctionne en arabe et en mode sombre', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        const AppBadge(AppBadgeType.verified),
        locale: const Locale('ar'),
        themeMode: ThemeMode.dark,
      ),
    );

    expect(find.text(ar.badgeVerified), findsOneWidget);
  });
}
