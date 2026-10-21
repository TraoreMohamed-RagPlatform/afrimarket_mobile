import 'dart:async';

import 'package:afrimarket_mobile/core/realtime/realtime_connection.dart';
import 'package:flutter_riverpod/misc.dart';

/// Fausse connexion temps réel : les tests envoient eux-mêmes événements
/// et fermetures ; aucune connexion réseau.
class FakeRealtimeConnection implements RealtimeConnection {
  final _events = StreamController<RealtimeEvent>.broadcast();
  final _closures = StreamController<RealtimeClosure>.broadcast();

  /// Jetons utilisés pour se connecter, dans l'ordre.
  final tokens = <String>[];
  int disconnects = 0;
  bool connected = false;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Stream<RealtimeClosure> get closures => _closures.stream;

  @override
  void connect({required String token}) {
    tokens.add(token);
    connected = true;
  }

  @override
  void disconnect() {
    disconnects++;
    connected = false;
  }

  /// Le serveur envoie [event].
  void emit(RealtimeEvent event) => _events.add(event);

  /// La connexion se ferme ([closure]).
  void close(RealtimeClosure closure) {
    connected = false;
    _closures.add(closure);
  }
}

/// Remplace la connexion temps réel de l'app.
List<Override> realtimeOverrides([FakeRealtimeConnection? connection]) => [
  realtimeConnectionProvider.overrideWithValue(
    connection ?? FakeRealtimeConnection(),
  ),
];
