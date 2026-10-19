import 'package:afrimarket_mobile/core/text/text_fold.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sans accents, minuscules, apostrophe droite', () {
    expect(foldText('Aïn Chock'), 'ain chock');
    expect(foldText('Ben M’Sick'), "ben m'sick");
    expect(foldText('  Ancienne Médina '), 'ancienne medina');
  });

  test('ordre alphabétique « naturel »', () {
    final names = ['Anfa', 'CIL', 'Aïn Chock', 'Californie', 'Ancienne Médina']
      ..sort(compareFolded);

    expect(names, [
      'Aïn Chock',
      'Ancienne Médina',
      'Anfa',
      'Californie',
      'CIL',
    ]);
  });
}
