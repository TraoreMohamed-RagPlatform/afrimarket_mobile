import 'package:afrimarket_mobile/shared/extensions/snackbar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n.dart';

void main() {
  testWidgets('message avec « Annuler »', (tester) async {
    var undone = false;
    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.showUndoSnackBar(
                'Annonce enregistrée',
                onUndo: () => undone = true,
              ),
              child: const Text('Enregistrer'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Annonce enregistrée'), findsOneWidget);

    await tester.tap(find.text(fr.undo));
    await tester.pumpAndSettle();
    expect(undone, isTrue);
  });

  testWidgets('un nouveau message remplace le précédent', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => context.showAppSnackBar('Premier'),
                  child: const Text('A'),
                ),
                TextButton(
                  onPressed: () => context.showAppSnackBar('Second'),
                  child: const Text('B'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();

    expect(find.text('Premier'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
  });
}
