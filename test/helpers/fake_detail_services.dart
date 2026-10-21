import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/platform/external_actions.dart';
import 'package:afrimarket_mobile/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:afrimarket_mobile/features/messaging/domain/repositories/messaging_repository.dart';

/// Faux dépôt de favoris : en mémoire, réponses configurables.
class FakeFavoritesRepository implements FavoritesRepository {
  final saved = <String>{};
  Result<void> answer = const Ok(null);

  @override
  Future<Result<bool>> isFavorite(String listingId) async =>
      Ok(saved.contains(listingId));

  @override
  Future<Result<void>> add(String listingId) async {
    if (answer.isOk) saved.add(listingId);
    return answer;
  }

  @override
  Future<Result<void>> remove(String listingId) async {
    if (answer.isOk) saved.remove(listingId);
    return answer;
  }
}

/// Faux dépôt de messagerie : mémorise les messages envoyés.
class FakeMessagingRepository implements MessagingRepository {
  /// Messages envoyés : (annonce, texte).
  final sent = <(String, String)>[];
  Result<void> answer = const Ok(null);

  @override
  Future<Result<void>> messageSeller({
    required String listingId,
    required String message,
  }) async {
    sent.add((listingId, message));
    return answer;
  }
}

/// Fausses actions externes : rien ne s'ouvre, tout est mémorisé.
class FakeExternalActions implements ExternalActions {
  final dialed = <String>[];
  final whatsapp = <(String, String?)>[];
  final shared = <String>[];
  bool canOpen = true;

  @override
  Future<bool> dial(String phone) async {
    dialed.add(phone);
    return canOpen;
  }

  @override
  Future<bool> openWhatsApp(String number, {String? message}) async {
    whatsapp.add((number, message));
    return canOpen;
  }

  @override
  Future<void> share(String text, {String? subject}) async {
    shared.add(text);
  }
}
