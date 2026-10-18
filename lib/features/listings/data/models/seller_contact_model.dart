import 'package:afrimarket_mobile/features/listings/domain/entities/seller_contact.dart';

/// DTO : réponse JSON de `GET /api/listings/:id/contact`.
///
/// ```json
/// { "phone": "+212612345678", "whatsapp": true }
/// ```
///
/// Sécurité : le numéro sert à construire une adresse `tel:` ou `wa.me`.
/// Il est réduit à des chiffres (et un « + » initial) : aucune autre
/// valeur ne peut atteindre ces adresses.
abstract final class SellerContactModel {
  /// Numéro international : « + », indicatif, 8 à 15 chiffres au total.
  static final RegExp _international = RegExp(r'^\+[1-9][0-9]{7,14}$');

  /// Séparateurs tolérés dans un numéro saisi (espaces, tirets...).
  static final RegExp _separators = RegExp(r'[\s.\-()]');

  /// Indicatif du Maroc, pour les numéros enregistrés au format national.
  static const _moroccoCode = '212';

  static SellerContact fromJson(Map<String, dynamic> json) {
    final phone = normalizePhone(json['phone']);
    if (phone == null) throw const FormatException('Numéro invalide');
    return SellerContact(phone: phone, whatsapp: json['whatsapp'] == true);
  }

  /// Numéro au format international (+212612345678), ou null s'il est
  /// invalide.
  ///
  /// - « 00 212 6… » → « +2126… » ;
  /// - « 06 12 34 56 78 » (national marocain) → « +212612345678 ».
  static String? normalizePhone(Object? raw) {
    if (raw is! String) return null;
    var phone = raw.replaceAll(_separators, '');
    if (phone.startsWith('00')) {
      phone = '+${phone.substring(2)}';
    } else if (RegExp(r'^0[5-7][0-9]{8}$').hasMatch(phone)) {
      phone = '+$_moroccoCode${phone.substring(1)}';
    }
    return _international.hasMatch(phone) ? phone : null;
  }
}
