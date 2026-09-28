import 'package:afrimarket_mobile/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Affiche le bouton de test backend', (tester) async {
    await tester.pumpWidget(const AfriMarketApp());
    expect(find.text('Tester la connexion'), findsOneWidget);
  });
}
