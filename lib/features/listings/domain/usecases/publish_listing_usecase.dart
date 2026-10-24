import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_draft.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listing_publisher.dart';

/// Étape en cours (affichée pendant la publication).
enum PublishStep { creating, uploadingPhotos, publishing }

/// Cas d'usage : publier une annonce.
///
/// 1. l'annonce est créée masquée ;
/// 2. les photos sont envoyées ;
/// 3. elle devient visible.
///
/// Si une étape échoue, l'annonce masquée est supprimée : jamais d'annonce
/// sans photo dans le fil, jamais d'annonce fantôme chez le vendeur.
class PublishListingUseCase {
  const new(this._publisher);

  final ListingPublisher _publisher;

  /// Renvoie l'identifiant de l'annonce publiée. Un brouillon incomplet
  /// est refusé ([ValidationFailure]) sans aucun appel au serveur.
  Future<Result<String>> call(
    ListingDraft draft, {
    void Function(PublishStep step)? onStep,
  }) async {
    if (!draft.isReady) return const Err(ValidationFailure());

    onStep?.call(PublishStep.creating);
    final created = await _publisher.createHidden(draft);
    final String id;
    switch (created) {
      case Ok(:final value):
        id = value;
      case Err(:final failure):
        return Err(failure);
    }

    onStep?.call(PublishStep.uploadingPhotos);
    final uploaded = await _publisher.uploadPhotos(id, draft.localPhotos);
    if (uploaded case Err(:final failure)) {
      return await _abandon(id, failure);
    }

    onStep?.call(PublishStep.publishing);
    final published = await _publisher.publish(id);
    if (published case Err(:final failure)) {
      return await _abandon(id, failure);
    }

    return Ok(id);
  }

  Future<Result<String>> _abandon(String id, Failure failure) async {
    // Au mieux : si la suppression échoue aussi, l'annonce reste masquée.
    await _publisher.delete(id);
    return Err(failure);
  }
}
