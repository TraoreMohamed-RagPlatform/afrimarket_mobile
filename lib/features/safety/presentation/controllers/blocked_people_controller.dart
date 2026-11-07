import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/blocked_person.dart';
import 'package:afrimarket_mobile/features/safety/safety_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Étape du chargement de la liste.
enum BlockedPeoplePhase { loading, ready, failed }

/// Réglages → Personnes bloquées.
@immutable
final class BlockedPeopleState {
  const new({
    this.phase = BlockedPeoplePhase.loading,
    this.items = const [],
    this.failure,
    this.actionFailure,
  });

  final BlockedPeoplePhase phase;
  final List<BlockedPerson> items;

  /// Échec du chargement (plein écran).
  final Failure? failure;

  /// Échec d'un « Débloquer » (message à afficher une fois).
  final Failure? actionFailure;

  bool get isEmpty => phase == BlockedPeoplePhase.ready && items.isEmpty;

  BlockedPeopleState copyWith({
    BlockedPeoplePhase? phase,
    List<BlockedPerson>? items,
    Failure? Function()? failure,
    Failure? Function()? actionFailure,
  }) {
    return BlockedPeopleState(
      phase: phase ?? this.phase,
      items: items ?? this.items,
      failure: failure == null ? this.failure : failure(),
      actionFailure: actionFailure == null
          ? this.actionFailure
          : actionFailure(),
    );
  }
}

/// Liste des personnes bloquées ; « Débloquer » les retire tout de suite
/// (remises en place si le serveur refuse).
class BlockedPeopleController extends Notifier<BlockedPeopleState> {
  @override
  BlockedPeopleState build() {
    unawaited(Future.microtask(_load));
    return const BlockedPeopleState();
  }

  /// « Réessayer » ou tirer pour actualiser.
  Future<void> refresh() {
    if (state.phase == BlockedPeoplePhase.failed) {
      state = const BlockedPeopleState();
    }
    return _load();
  }

  /// Débloque [userId] ; renvoie vrai si c'est fait.
  Future<bool> unblock(String userId) async {
    final before = state.items;
    if (!before.any((person) => person.userId == userId)) return false;
    state = state.copyWith(
      items: [
        for (final person in before)
          if (person.userId != userId) person,
      ],
    );
    final result = await ref.read(safetyUseCasesProvider).unblock(userId);
    if (!ref.mounted) return false;
    if (result case Err(:final failure)) {
      state = state.copyWith(items: before, actionFailure: () => failure);
      return false;
    }
    return true;
  }

  /// Le message d'échec a été affiché.
  void actionFailureShown() =>
      state = state.copyWith(actionFailure: () => null);

  Future<void> _load() async {
    final result = await ref.read(safetyUseCasesProvider).blockedPeople();
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        state = BlockedPeopleState(
          phase: BlockedPeoplePhase.ready,
          items: value,
        );
      case Err(:final failure):
        state = state.phase == BlockedPeoplePhase.ready
            ? state.copyWith(actionFailure: () => failure)
            : BlockedPeopleState(
                phase: BlockedPeoplePhase.failed,
                failure: failure,
              );
    }
  }
}

/// Écran « Personnes bloquées » ; libéré à sa fermeture.
final NotifierProvider<BlockedPeopleController, BlockedPeopleState>
blockedPeopleControllerProvider = NotifierProvider.autoDispose(
  BlockedPeopleController.new,
);
