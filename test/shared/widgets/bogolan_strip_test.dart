import 'package:afrimarket_mobile/shared/widgets/bogolan_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

void main() {
  testWidgets('occupe toute la largeur, sans débordement', (tester) async {
    await tester.pumpWidget(
      localizedApp(const Column(children: [BogolanStrip(color: Colors.brown)])),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(BogolanStrip)).width,
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
    );
  });

  testWidgets('décoratif : ignoré par les lecteurs d’écran', (tester) async {
    await tester.pumpWidget(
      localizedApp(const BogolanStrip(color: Colors.brown)),
    );

    expect(
      find.descendant(
        of: find.byType(BogolanStrip),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
  });

  test('ne redessine que si la couleur change', () {
    const painter = BogolanPainter(color: Colors.brown);

    expect(
      painter.shouldRepaint(const BogolanPainter(color: Colors.brown)),
      isFalse,
    );
    expect(
      painter.shouldRepaint(const BogolanPainter(color: Colors.black)),
      isTrue,
    );
  });
}
