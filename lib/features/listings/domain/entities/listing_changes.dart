import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:meta/meta.dart';

/// Champs modifiés d'une annonce (écran « Modifier ») : seuls ceux-ci sont
/// envoyés au serveur. `null` = inchangé.
@immutable
final class ListingChanges {
  const new({
    this.title,
    this.description,
    this.price,
    this.categoryId,
    this.district,
    this.condition,
    this.isNegotiable,
    this.deliveryMode,
  });

  /// Différences entre l'annonce en ligne ([before]) et la saisie
  /// ([after]). Les textes sont comparés sans les espaces autour.
  factory between(ListingDraft before, ListingDraft after) {
    String? changedText(String a, String b) =>
        a.trim() == b.trim() ? null : b.trim();
    T? changed<T extends Object>(T? a, T? b) => a == b ? null : b;

    return ListingChanges(
      title: changedText(before.title, after.title),
      description: changedText(before.description, after.description),
      price: changed(before.price, after.price),
      categoryId: changed(before.categoryId, after.categoryId),
      district: changed(before.district, after.district),
      condition: changed(before.condition, after.condition),
      isNegotiable: changed(before.isNegotiable, after.isNegotiable),
      deliveryMode: changed(before.deliveryMode, after.deliveryMode),
    );
  }

  final String? title;
  final String? description;
  final int? price;
  final String? categoryId;
  final String? district;
  final ListingCondition? condition;
  final bool? isNegotiable;
  final DeliveryMode? deliveryMode;

  /// Rien à envoyer.
  bool get isEmpty =>
      title == null &&
      description == null &&
      price == null &&
      categoryId == null &&
      district == null &&
      condition == null &&
      isNegotiable == null &&
      deliveryMode == null;

  @override
  bool operator ==(Object other) =>
      other is ListingChanges &&
      other.title == title &&
      other.description == description &&
      other.price == price &&
      other.categoryId == categoryId &&
      other.district == district &&
      other.condition == condition &&
      other.isNegotiable == isNegotiable &&
      other.deliveryMode == deliveryMode;

  @override
  int get hashCode => Object.hash(
    title,
    description,
    price,
    categoryId,
    district,
    condition,
    isNegotiable,
    deliveryMode,
  );
}
