import 'package:afrimarket_mobile/shared/widgets/price_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

/// Texte affiché, espaces insécables normalisés.
String _shownText(WidgetTester tester) {
  final text = tester.widget<Text>(find.byType(Text)).textSpan!.toPlainText();
  return text.replaceAll(RegExp('[\u00A0\u202F]'), ' ');
}

void main() {
  testWidgets('affiche le prix', (tester) async {
    await tester.pumpWidget(localizedApp(const PriceText(price: 800)));

    expect(_shownText(tester), '800 DH');
  });

  testWidgets('affiche l’ancien prix barré en cas de baisse', (tester) async {
    await tester.pumpWidget(
      localizedApp(const PriceText(price: 800, oldPrice: 1200)),
    );

    expect(_shownText(tester), contains('1 200 DH'));
    final text = tester.widget<Text>(find.byType(Text));
    final spans = (text.textSpan! as TextSpan).children!;
    expect(
      spans.whereType<TextSpan>().any(
        (s) => s.style?.decoration == TextDecoration.lineThrough,
      ),
      isTrue,
    );
  });

  testWidgets('n’affiche pas un ancien prix inférieur', (tester) async {
    await tester.pumpWidget(
      localizedApp(const PriceText(price: 800, oldPrice: 500)),
    );

    expect(_shownText(tester), '800 DH');
  });
}
