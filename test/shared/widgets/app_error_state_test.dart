import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/l10n/failure_messages.dart';
import 'package:afrimarket_mobile/shared/widgets/app_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

void main() {
  const failure = TimeoutFailure();

  testWidgets('plein écran : message traduit, icône réseau, Réessayer', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      localizedApp(
        AppErrorState(failure: failure, onRetry: () => retried = true),
      ),
    );

    expect(find.text(failure.message(fr)), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

    await tester.tap(find.text(fr.retry));
    expect(retried, isTrue);
  });

  testWidgets('compacte : une ligne avec Réessayer', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      localizedApp(
        AppErrorState(
          failure: failure,
          compact: true,
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.byType(TextButton), findsOneWidget);
    await tester.tap(find.text(fr.retry));
    expect(retried, isTrue);
  });

  testWidgets('message annoncé automatiquement (liveRegion)', (tester) async {
    await tester.pumpWidget(
      localizedApp(const AppErrorState(failure: failure)),
    );

    expect(
      tester.getSemantics(find.text(failure.message(fr))),
      isSemantics(isLiveRegion: true),
    );
  });

  testWidgets('arabe, mode sombre et texte doublé (2 variantes)', (
    tester,
  ) async {
    for (final compact in [false, true]) {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: localizedApp(
            AppErrorState(failure: failure, compact: compact, onRetry: () {}),
            locale: const Locale('ar'),
            themeMode: ThemeMode.dark,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    }
  });
}
