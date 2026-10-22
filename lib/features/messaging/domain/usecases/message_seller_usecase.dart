import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/messaging/domain/message_rules.dart';
import 'package:afrimarket_mobile/features/messaging/domain/repositories/messaging_repository.dart';

/// Cas d'usage : écrire au vendeur depuis une annonce.
class MessageSellerUseCase {
  const new(this._repository);

  /// Longueur maximale d'un message.
  static const int maxLength = MessageRules.maxLength;

  final MessagingRepository _repository;

  /// Le message est nettoyé des espaces autour. Vide ou trop long :
  /// [ValidationFailure], sans appel au serveur.
  ///
  /// Refus du serveur : [ValidationFailure] (sa propre annonce),
  /// [ConflictFailure] (voir `MessagingConflicts`), [NotFoundFailure]
  /// (annonce retirée).
  Future<Result<void>> call({
    required String listingId,
    required String message,
  }) {
    final text = MessageRules.clean(message);
    if (text == null) {
      return Future.value(const Err(ValidationFailure()));
    }
    return _repository.messageSeller(listingId: listingId, message: text);
  }
}
