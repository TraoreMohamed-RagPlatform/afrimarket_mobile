import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/features/health/domain/entities/health_status.dart';
import 'package:afrimarket_mobile/features/health/health_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// États possibles de l'écran de diagnostic (classe scellée).
sealed class HealthState {
  const new();
}

/// Aucun test lancé.
final class HealthIdle extends HealthState {
  const new();
}

/// Test en cours.
final class HealthLoading extends HealthState {
  const new();
}

/// Le serveur a répondu.
final class HealthLoaded extends HealthState {
  const new(this.status);

  final HealthStatus status;
}

/// Le test a échoué.
final class HealthFailed extends HealthState {
  const new(this.failure);

  final Failure failure;
}

/// Pilote l'écran de diagnostic.
class HealthController extends Notifier<HealthState> {
  @override
  HealthState build() => const HealthIdle();

  /// Lance le test de santé. Ignoré si un test est déjà en cours.
  Future<void> check() async {
    if (state is HealthLoading) return;
    state = const HealthLoading();

    final result = await ref.read(checkHealthUseCaseProvider)();
    if (!ref.mounted) return;

    state = switch (result) {
      Ok(:final value) => HealthLoaded(value),
      Err(:final failure) => HealthFailed(failure),
    };
  }
}

final NotifierProvider<HealthController, HealthState> healthControllerProvider =
    NotifierProvider.autoDispose<HealthController, HealthState>(
      HealthController.new,
    );
