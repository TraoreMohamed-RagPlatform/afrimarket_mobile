import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/features/favorites/favorites_providers.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_detail.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_locations.dart';
import 'package:afrimarket_mobile/features/listings/domain/entities/listing_summary.dart';
import 'package:afrimarket_mobile/features/listings/listings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Annonce complète, par identifiant.
///
/// Libérée en quittant la page ; `ref.invalidate` (« Réessayer ») la
/// recharge.
final FutureProviderFamily<Result<ListingDetail>, String>
listingDetailProvider = FutureProvider.autoDispose
    .family<Result<ListingDetail>, String>(
      // « isOwner » dépend de la personne connectée : après une connexion
      // depuis cette page, elle est rouverte, donc relue.
      (ref, id) => ref.watch(getListingDetailUseCaseProvider)(id),
    );

/// Annonces similaires à une annonce.
final FutureProviderFamily<Result<List<ListingSummary>>, String>
similarListingsProvider = FutureProvider.autoDispose
    .family<Result<List<ListingSummary>>, String>(
      (ref, id) => ref.watch(getSimilarListingsUseCaseProvider)(id),
    );

/// Noms des villes et quartiers.
///
/// Gardés en mémoire pour toute la session une fois chargés ; un échec
/// n'est pas mémorisé (nouvel essai à la prochaine annonce). En attendant,
/// le lieu n'est simplement pas affiché.
final FutureProvider<ListingLocations> listingLocationsProvider =
    FutureProvider.autoDispose<ListingLocations>((ref) async {
      final link = ref.keepAlive();
      final result = await ref.watch(getListingLocationsUseCaseProvider)();
      switch (result) {
        case Ok(:final value):
          return value;
        case Err():
          link.close();
          return ListingLocations.empty;
      }
    });

/// Annonce enregistrée ou non, et action en cours.
final class FavoriteState {
  const new({this.saved = false, this.busy = false});

  final bool saved;

  /// Vrai pendant l'enregistrement (ou le retrait) : un second appui est
  /// ignoré.
  final bool busy;
}

/// Bouton « Enregistrer » d'une annonce.
///
/// - visiteur : jamais enregistrée (la page l'invite à se connecter) ;
/// - connecté : l'état est lu sur le serveur, puis mis à jour tout de
///   suite à l'appui (affichage optimiste), et rétabli en cas d'échec.
class FavoriteController extends Notifier<FavoriteState> {
  new(this.listingId);

  final String listingId;

  @override
  FavoriteState build() {
    final signedIn = ref.watch(sessionProvider) == SessionStatus.authenticated;
    if (signedIn) unawaited(_load());
    return const FavoriteState();
  }

  Future<void> _load() async {
    final result = await ref.read(getFavoriteStatusUseCaseProvider)(listingId);
    if (!ref.mounted || state.busy) return;
    if (result case Ok(:final value)) state = FavoriteState(saved: value);
  }

  /// Enregistre ou retire l'annonce. Renvoie l'échec éventuel (l'état est
  /// alors rétabli), ou null si l'action a réussi ou a été ignorée.
  Future<Failure?> toggle() async {
    final current = state;
    if (current.busy) return null;
    final saved = !current.saved;
    state = FavoriteState(saved: saved, busy: true);

    final result = await ref.read(setFavoriteUseCaseProvider)(
      listingId,
      saved: saved,
    );
    if (!ref.mounted) return null;

    switch (result) {
      case Ok():
        state = FavoriteState(saved: saved);
        return null;
      case Err(:final failure):
        state = FavoriteState(saved: current.saved);
        return failure;
    }
  }
}

final NotifierProviderFamily<FavoriteController, FavoriteState, String>
favoriteControllerProvider = NotifierProvider.autoDispose
    .family<FavoriteController, FavoriteState, String>(FavoriteController.new);
