import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Actions qui ouvrent une autre application : téléphone, WhatsApp,
/// feuille de partage du système.
///
/// Interface séparée : les tests la remplacent par un faux, sans jamais
/// ouvrir d'application.
abstract interface class ExternalActions {
  /// Ouvre le composeur avec [phone] (« +212612345678 »), sans appeler.
  /// Faux si aucune application ne peut l'ouvrir.
  Future<bool> dial(String phone);

  /// Ouvre une discussion WhatsApp avec [number] (chiffres seuls, avec
  /// l'indicatif), [message] prérempli. Faux si impossible.
  Future<bool> openWhatsApp(String number, {String? message});

  /// Ouvre la feuille de partage du système avec [text].
  Future<void> share(String text, {String? subject});
}

/// Implémentation réelle (url_launcher, share_plus).
///
/// Sécurité : les adresses sont construites ici, à partir de valeurs déjà
/// validées (chiffres seuls) ; aucune adresse reçue du serveur n'est
/// ouverte telle quelle.
class PlatformExternalActions implements ExternalActions {
  const new();

  static final RegExp _phone = RegExp(r'^\+?[0-9]{8,15}$');

  @override
  Future<bool> dial(String phone) {
    if (!_phone.hasMatch(phone)) return Future.value(false);
    return _launch(Uri(scheme: 'tel', path: phone));
  }

  @override
  Future<bool> openWhatsApp(String number, {String? message}) {
    final digits = number.replaceFirst('+', '');
    if (!_phone.hasMatch(digits)) return Future.value(false);
    final query = message == null || message.isEmpty ? null : {'text': message};
    return _launch(Uri.https('wa.me', '/$digits', query));
  }

  @override
  Future<void> share(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      // Aucune application compatible : l'appelant affiche un message.
      return false;
    }
  }
}

final externalActionsProvider = Provider<ExternalActions>(
  (ref) => const PlatformExternalActions(),
);
