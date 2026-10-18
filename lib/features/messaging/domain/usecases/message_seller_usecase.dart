import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/messaging/domain/repositories/messaging_repository.dart';

/// Cas d'usage : écrire au vendeur depuis une annonce.
class MessageSellerUseCase {
  const new(this._repository);

  /// Longueur maximale d'un message.
  static const maxLength = 1000;

  final MessagingRepository _repository;

  /// Le message est nettoyé des espaces autour. Vide ou trop long :
  /// [ValidationFailure], sans appel au serveur.
  Future<Result<void>> call({
    required String sellerId,
    required String message,
  }) {
    final text = message.trim();
    if (text.isEmpty || text.runes.length > maxLength) {
      return Future.value(const Err(ValidationFailure()));
    }
    return _repository.messageSeller(sellerId: sellerId, message: text);
  }
}
