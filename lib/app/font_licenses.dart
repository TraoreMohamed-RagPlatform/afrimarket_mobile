import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Licences des polices intégrées à l'app (ADR 0011).
///
/// La licence OFL de Bricolage Grotesque et la licence MIT de Phosphor
/// exigent d'accompagner les fichiers de police : elles apparaissent dans
/// la page « Licences » de l'app.
abstract final class FontLicenses {
  /// Fichiers de licence, déclarés comme assets dans `pubspec.yaml`.
  static const entries = <({String package, String asset})>[
    (package: 'Bricolage Grotesque', asset: 'assets/fonts/bricolage/OFL.txt'),
    (package: 'Phosphor Icons', asset: 'assets/fonts/phosphor/LICENSE'),
  ];

  /// Ajoute les licences au registre de Flutter (lecture paresseuse).
  static void register({AssetBundle? bundle}) {
    final source = bundle ?? rootBundle;
    LicenseRegistry.addLicense(() async* {
      for (final entry in entries) {
        final text = await source.loadString(entry.asset);
        yield LicenseEntryWithLineBreaks([entry.package], text);
      }
    });
  }
}
