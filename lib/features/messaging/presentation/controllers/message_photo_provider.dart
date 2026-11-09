import 'dart:async';
import 'dart:typed_data';

import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/messaging/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Durée pendant laquelle une photo reste en mémoire après avoir quitté
/// l'écran (retour rapide sur la discussion, ouverture en grand).
const messagePhotoKeepAlive = Duration(minutes: 5);

/// Image d'une photo de message, par identifiant du message.
///
/// Les photos sont privées : elles passent par le client de l'API
/// (connexion requise), jamais par une adresse publique. Gardées en
/// mémoire seulement (rien n'est écrit sur le téléphone) ; un échec n'est
/// pas gardé (nouvel essai à la prochaine lecture).
final FutureProviderFamily<Result<Uint8List>, String> messagePhotoProvider =
    FutureProvider.autoDispose.family<Result<Uint8List>, String>((
      ref,
      messageId,
    ) async {
      final result = await ref.read(getMessagePhotoUseCaseProvider)(messageId);
      if (result is Ok<Uint8List>) {
        final link = ref.keepAlive();
        Timer? timer;
        ref
          ..onCancel(() => timer = Timer(messagePhotoKeepAlive, link.close))
          ..onResume(() => timer?.cancel())
          ..onDispose(() => timer?.cancel());
      }
      return result;
    });
