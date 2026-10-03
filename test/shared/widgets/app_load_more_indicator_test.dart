import 'package:afrimarket_mobile/shared/widgets/app_load_more_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

void main() {
  testWidgets('indicateur annoncé aux lecteurs d’écran', (tester) async {
    await tester.pumpWidget(localizedApp(const AppLoadMoreIndicator()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel(fr.loadingLabel), findsOneWidget);
  });
}
