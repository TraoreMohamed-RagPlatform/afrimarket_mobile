import 'dart:async';

import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Événements temps réel envoyés par le serveur (liste fermée, identique
/// à `services/realtime.js` côté backend).
enum RealtimeEvent {
  notification('notification:new'),
  message('message:new');

  new(this.wireName);

  /// Nom de l'événement Socket.io.
  final String wireName;
}

/// Pourquoi la connexion s'est fermée.
enum RealtimeClosure {
  /// Refusée ou coupée par le serveur (jeton expiré, déconnexion de tous
  /// les appareils...) : se reconnecter avec un jeton neuf.
  byServer,

  /// Réseau perdu ou serveur injoignable.
  network,
}

/// Connexion temps réel (Socket.io) avec le serveur AfriMarket.
///
/// Interface séparée : les tests la remplacent par un faux.
abstract interface class RealtimeConnection {
  /// Événements reçus.
  Stream<RealtimeEvent> get events;

  /// Fermetures de la connexion.
  Stream<RealtimeClosure> get closures;

  /// Ouvre la connexion avec le jeton d'accès [token].
  void connect({required String token});

  /// Ferme la connexion (sans effet si elle est déjà fermée).
  void disconnect();
}

/// Implémentation réelle (socket_io_client).
///
/// Sécurité :
/// - jeton envoyé dans `auth` de la poignée de main, jamais dans l'adresse
///   (les adresses finissent dans les journaux) ;
/// - WebSocket seulement ; en staging et en production l'adresse de l'API
///   est en HTTPS, donc la connexion est chiffrée (wss) ;
/// - pas de reconnexion automatique avec un vieux jeton : c'est
///   `RealtimeController` qui se reconnecte, avec un jeton neuf ;
/// - seuls les événements connus sont transmis ; leur contenu n'est pas lu
///   (l'app relit ses compteurs par l'API).
class SocketIoRealtimeConnection implements RealtimeConnection {
  new(this._baseUrl);

  final Uri _baseUrl;
  io.Socket? _socket;
  final _events = StreamController<RealtimeEvent>.broadcast();
  final _closures = StreamController<RealtimeClosure>.broadcast();

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Stream<RealtimeClosure> get closures => _closures.stream;

  @override
  void connect({required String token}) {
    disconnect();
    final socket = io.io(
      _baseUrl.toString(),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .disableReconnection()
          .enableForceNew()
          .setAuth({'token': token})
          .build(),
    );
    for (final event in RealtimeEvent.values) {
      socket.on(event.wireName, (_) => _events.add(event));
    }
    socket
      ..onConnectError((_) => _closed(socket, RealtimeClosure.byServer))
      ..onDisconnect((reason) {
        _closed(
          socket,
          reason == 'io server disconnect'
              ? RealtimeClosure.byServer
              : RealtimeClosure.network,
        );
      })
      ..connect();
    _socket = socket;
  }

  void _closed(io.Socket socket, RealtimeClosure closure) {
    // Une ancienne connexion (remplacée) ne signale plus rien.
    if (!identical(socket, _socket)) return;
    _socket = null;
    socket.dispose();
    _closures.add(closure);
  }

  @override
  void disconnect() {
    final socket = _socket;
    _socket = null;
    socket?.dispose();
  }
}

final realtimeConnectionProvider = Provider<RealtimeConnection>((ref) {
  final connection = SocketIoRealtimeConnection(
    ref.watch(appConfigProvider).apiBaseUrl,
  );
  ref.onDispose(connection.disconnect);
  return connection;
});
