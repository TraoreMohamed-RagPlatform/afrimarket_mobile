import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

Future<TextDirection> _directionFor(WidgetTester tester, Locale locale) async {
  late TextDirection direction;

  await tester.pumpWidget(
    localizedApp(
      Builder(
        builder: (context) {
          direction = Directionality.of(context);
          return const SizedBox();
        },
      ),
      locale: locale,
    ),
  );
  return direction;
}

void main() {
  testWidgets('l’arabe s’affiche de droite à gauche', (tester) async {
    expect(await _directionFor(tester, const Locale('ar')), TextDirection.rtl);
  });

  testWidgets('le français s’affiche de gauche à droite', (tester) async {
    expect(await _directionFor(tester, const Locale('fr')), TextDirection.ltr);
  });

  testWidgets('l’anglais s’affiche de gauche à droite', (tester) async {
    expect(await _directionFor(tester, const Locale('en')), TextDirection.ltr);
  });
}
