import 'package:afrimarket_mobile/core/config/dev_tools.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jamais en staging ni en prod', () {
    expect(devToolsVisible(Flavor.staging), isFalse);
    expect(devToolsVisible(Flavor.prod), isFalse);
  });

  test('en dev : seulement si les outils sont compilés', () {
    expect(devToolsVisible(Flavor.dev), kDevToolsEnabled);
  });
}
