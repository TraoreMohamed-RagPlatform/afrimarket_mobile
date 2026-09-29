import 'package:afrimarket_mobile/core/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Raccourci : `context.l10n.loginTitle`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
