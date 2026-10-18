import 'package:afrimarket_mobile/features/listings/data/models/seller_contact_model.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/seller_contact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('numéro international et WhatsApp', () {
    final contact = SellerContactModel.fromJson({
      'phone': '+212612345678',
      'whatsapp': true,
    });

    expect(
      contact,
      const SellerContact(phone: '+212612345678', whatsapp: true),
    );
    expect(contact.whatsappNumber, '212612345678');
  });

  group('normalizePhone', () {
    for (final (raw, expected) in [
      ('+212 6 12 34 56 78', '+212612345678'),
      ('0612345678', '+212612345678'),
      ('07-12-34-56-78', '+212712345678'),
      ('00212612345678', '+212612345678'),
      ('+225 07 08 09 10 11', '+2250708091011'),
    ]) {
      test('« $raw » → $expected', () {
        expect(SellerContactModel.normalizePhone(raw), expected);
      });
    }

    for (final raw in [
      null,
      42,
      '',
      'abc',
      '+212',
      '+0612345678',
      '+212612345678;rm',
      'tel:+212612345678',
      '+2126123456789012345',
    ]) {
      test('refusé : $raw', () {
        expect(SellerContactModel.normalizePhone(raw), isNull);
      });
    }
  });

  test('numéro invalide : FormatException', () {
    expect(
      () => SellerContactModel.fromJson({'phone': 'javascript:alert(1)'}),
      throwsFormatException,
    );
  });

  test('WhatsApp absent : faux', () {
    expect(
      SellerContactModel.fromJson({'phone': '+212612345678'}).whatsapp,
      isFalse,
    );
  });
}
