import 'package:afrimarket_mobile/shared/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

void main() {
  group('AppNetworkImage.isAllowedUrl', () {
    test('accepte https et http', () {
      expect(
        AppNetworkImage.isAllowedUrl('https://api.example.com/a.jpg'),
        isTrue,
      );
      expect(
        AppNetworkImage.isAllowedUrl('http://10.0.2.2:3000/a.jpg'),
        isTrue,
      );
    });

    test('refuse les autres schémas (sécurité)', () {
      expect(AppNetworkImage.isAllowedUrl('file:///data/secret.jpg'), isFalse);
      expect(AppNetworkImage.isAllowedUrl('javascript:alert(1)'), isFalse);
      expect(AppNetworkImage.isAllowedUrl('/uploads/a.jpg'), isFalse);
      expect(AppNetworkImage.isAllowedUrl(null), isFalse);
    });
  });

  testWidgets('sans image : fond neutre avec une icône', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        const SizedBox(
          width: 100,
          height: 100,
          child: AppNetworkImage(url: null),
        ),
      ),
    );

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('adresse refusée : fond neutre, aucun chargement', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        const SizedBox(
          width: 100,
          height: 100,
          child: AppNetworkImage(url: 'file:///data/secret.jpg'),
        ),
      ),
    );

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });
}
