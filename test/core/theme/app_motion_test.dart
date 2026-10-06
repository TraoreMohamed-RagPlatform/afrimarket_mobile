import 'package:afrimarket_mobile/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Duration> resolveWith(
    WidgetTester tester, {
    required bool reduce,
  }) async {
    late Duration resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Builder(
          builder: (context) {
            resolved = AppMotion.resolve(context, AppMotion.normal);
            return const SizedBox();
          },
        ),
      ),
    );
    return resolved;
  }

  testWidgets('durée normale si les animations sont actives', (tester) async {
    expect(await resolveWith(tester, reduce: false), AppMotion.normal);
  });

  testWidgets('durée nulle si « Réduire les animations »', (tester) async {
    expect(await resolveWith(tester, reduce: true), Duration.zero);
  });
}
