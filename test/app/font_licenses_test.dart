import 'dart:convert';

import 'package:afrimarket_mobile/app/font_licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode('Licence de $key')));

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      'Licence de $key';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('les licences des polices apparaissent dans la page Licences', () async {
    FontLicenses.register(bundle: _FakeBundle());

    final entries = await LicenseRegistry.licenses.toList();
    final packages = entries.expand((entry) => entry.packages).toSet();

    expect(packages, containsAll(['Bricolage Grotesque', 'Phosphor Icons']));
  });

  test('chaque licence est un fichier déclaré dans pubspec.yaml', () {
    expect(
      FontLicenses.entries.map((entry) => entry.asset),
      containsAll([
        'assets/fonts/bricolage/OFL.txt',
        'assets/fonts/phosphor/LICENSE',
      ]),
    );
  });
}
