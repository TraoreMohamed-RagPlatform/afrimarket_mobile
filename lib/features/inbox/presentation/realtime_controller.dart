import 'dart:async';

import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/realtime/realtime_connection.dart';
import 'package:afrimarket_mobile/core/session/session_provider.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/features/inbox/presentation/unread_counts_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État de la connexion temps réel.
enum RealtimeStatus { off, connecting, waitingToRetry }

/// Garde la connexion temps réel ouverte tant que la personne est connectée
/// et que l'app est au premier plan, et met à jour les pastilles de
/// non-lus dès qu'un message ou une notification arrive.
///
/// Piloté par la barre du bas (`AppShell`) : [start] quand elle apparaît,
/// [pause] / [resume] avec l'app, [stop] quand elle disparaît.
///
/// Fermeture par le serveur (jeton expiré...) : nouvel essai après un délai
/// croissant ; avant de se reconnecter, les compteurs sont relus par l'API,
/// ce qui renouvelle le jeton d'accès s'il a expiré.
class RealtimeController extends Notifier<RealtimeStatus> {
  /// Délais entre deux essais : rapide d'abord, puis plus espacé.
  static const retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(minutes: 1),
  ];

  bool _active = false;
  int _attempt = 0;
  Timer? _retry;
  StreamSubscription<RealtimeEvent>? _events;
  StreamSubscription<RealtimeClosure>? _closures;

  /// Lue dans [build] : utilisable aussi pendant la libération
  /// (`onDispose` n'a plus le droit de lire d'autres providers).
  late RealtimeConnection _connection;

  bool get _signedIn =>
      ref.read(sessionProvider) == SessionStatus.authenticated;

  @override
  RealtimeStatus build() {
    _connection = ref.read(realtimeConnectionProvider);
    ref
      ..listen<SessionStatus>(sessionProvider, (previous, next) {
        if (!_active) return;
        if (next == SessionStatus.authenticated) {
          unawaited(_connect());
        } else {
          _close();
        }
      })
      ..onDispose(() => _close(notify: false));
    return RealtimeStatus.off;
  }

  /// La barre du bas est affichée : connexion si la personne est connectée.
  void start() {
    if (_active) return;
    _active = true;
    _events ??= _connection.events.listen((_) => _refreshCounts());
    _closures ??= _connection.closures.listen(_onClosed);
    // Appelé depuis initState : la connexion (qui change l'état) démarre
    // juste après, jamais pendant la construction des écrans.
    if (_signedIn) unawaited(Future.microtask(_connect));
  }

  /// L'app passe en arrière-plan : connexion fermée (batterie).
  void pause() {
    if (!_active) return;
    _active = false;
    _close();
  }

  /// L'app revient au premier plan.
  void resume() => start();

  /// La barre du bas disparaît.
  void stop() {
    _active = false;
    // Appelé pendant la fermeture de l'écran : pas de changement d'état.
    _close(notify: false);
    unawaited(_events?.cancel());
    unawaited(_closures?.cancel());
    _events = null;
    _closures = null;
  }

  Future<void> _connect() async {
    _retry?.cancel();
    if (!_active || !_signedIn) return;
    state = RealtimeStatus.connecting;
    final token = await ref.read(tokenStorageProvider).readAccessToken();
    if (!ref.mounted || !_active || !_signedIn) return;
    if (token case Ok(value: final value?) when value.isNotEmpty) {
      _connection.connect(token: value);
    } else {
      _scheduleRetry();
    }
  }

  void _onClosed(RealtimeClosure closure) {
    if (!_active || !_signedIn) return;
    _scheduleRetry();
  }

  void _scheduleRetry() {
    _retry?.cancel();
    final delay = retryDelays[_attempt.clamp(0, retryDelays.length - 1)];
    _attempt++;
    state = RealtimeStatus.waitingToRetry;
    _retry = Timer(delay, () async {
      // Relire par l'API renouvelle le jeton s'il a expiré.
      await ref.read(unreadCountsProvider.notifier).refresh();
      if (ref.mounted) await _connect();
    });
  }

  void _refreshCounts() {
    _attempt = 0;
    unawaited(ref.read(unreadCountsProvider.notifier).refresh());
  }

  void _close({bool notify = true}) {
    _retry?.cancel();
    _retry = null;
    _attempt = 0;
    _connection.disconnect();
    if (notify && ref.mounted) state = RealtimeStatus.off;
  }
}

final NotifierProvider<RealtimeController, RealtimeStatus> realtimeProvider =
    NotifierProvider<RealtimeController, RealtimeStatus>(
      RealtimeController.new,
    );
