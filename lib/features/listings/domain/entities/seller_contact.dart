import 'package:meta/meta.dart';

/// Numéro du vendeur, obtenu à la demande (connexion requise).
///
/// Le numéro n'est jamais conservé : il sert à ouvrir l'appel ou
/// WhatsApp, puis il est oublié.
@immutable
final class SellerContact {
  const new({required this.phone, this.whatsapp = false});

  /// Numéro international, chiffres seuls après un « + » (ex. +212612345678).
  final String phone;

  /// Vrai si le vendeur accepte d'être contacté sur WhatsApp.
  final bool whatsapp;

  /// Numéro pour WhatsApp (wa.me) : chiffres seuls, sans « + ».
  String get whatsappNumber => phone.replaceFirst('+', '');

  @override
  bool operator ==(Object other) =>
      other is SellerContact &&
      other.phone == phone &&
      other.whatsapp == whatsapp;

  @override
  int get hashCode => Object.hash(phone, whatsapp);
}
