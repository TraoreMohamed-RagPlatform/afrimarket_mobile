import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afrimarket_mobile/shared/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

void main() {
  group('UserAvatar.initialsOf', () {
    test('deux initiales au maximum', () {
      expect(UserAvatar.initialsOf('Fatou Hmimid'), 'FH');
      expect(UserAvatar.initialsOf('Awa Marie Diallo'), 'AM');
      expect(UserAvatar.initialsOf('moussa'), 'M');
    });

    test('nom arabe et nom vide', () {
      expect(UserAvatar.initialsOf('محمد علي'), 'مع');
      expect(UserAvatar.initialsOf('   '), '?');
    });
  });

  testWidgets('initiales si pas de photo', (tester) async {
    await tester.pumpWidget(
      localizedApp(const Center(child: UserAvatar(name: 'Fatou Hmimid'))),
    );

    expect(find.text('FH'), findsOneWidget);
  });

  testWidgets('badge vérifié annoncé aux lecteurs d’écran', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        const Center(child: UserAvatar(name: 'Fatou H.', verified: true)),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      find.bySemanticsLabel(fr.avatarVerified('Fatou H.')),
      findsOneWidget,
    );
  });

  testWidgets('adresse de photo refusée : initiales', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        const Center(
          child: UserAvatar(name: 'Fatou H.', imageUrl: 'file:///secret.jpg'),
        ),
      ),
    );

    expect(find.text('FH'), findsOneWidget);
  });

  testWidgets('arabe, mode sombre et texte doublé', (tester) async {
    final ar = lookupAppLocalizations(const Locale('ar'));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: localizedApp(
          const Center(
            child: UserAvatar(
              name: 'محمد علي',
              size: AvatarSize.large,
              verified: true,
            ),
          ),
          locale: const Locale('ar'),
          themeMode: ThemeMode.dark,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.bySemanticsLabel(ar.avatarVerified('محمد علي')),
      findsOneWidget,
    );
  });
}
