import 'dart:async';

import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
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

/// Socket.io réduit à ce que l'app utilise.
///
/// Séparé de [SocketIoRealtimeConnection] : les tests le remplacent par un
/// faux, sans réseau.
abstract interface class RealtimeSocket {
  /// [handler] est appelé à chaque événement [event] du serveur.
  void on(String event, void Function(dynamic data) handler);

  /// [handler] est appelé si la connexion est refusée ou impossible.
  void onConnectError(void Function(dynamic error) handler);

  /// [handler] reçoit la raison de la fermeture.
  void onDisconnect(void Function(dynamic reason) handler);

  /// Ouvre la connexion.
  void connect();

  /// Ferme la connexion et libère le socket.
  void dispose();
}

/// Crée (sans le connecter) un socket vers [baseUrl] avec le jeton [token].
typedef RealtimeSocketFactory = RealtimeSocket Function(
  Uri baseUrl,
  String token,
);

/// Socket réel (socket_io_client), créé sans se connecter.
final class SocketIoSocket implements RealtimeSocket {
  new(Uri baseUrl, String token)
    : _socket = io.io(baseUrl.toString(), options(token));

  final io.Socket _socket;

  /// Options de la poignée de main.
  ///
  /// Sécurité :
  /// - jeton dans `auth`, jamais dans l'adresse (les adresses finissent
  ///   dans les journaux) ;
  /// - WebSocket seulement ; en staging et en production l'adresse de l'API
  ///   est en HTTPS, donc la connexion est chiffrée (wss) ;
  /// - pas de reconnexion automatique avec un vieux jeton : c'est
  ///   `RealtimeController` qui se reconnecte, avec un jeton neuf.
  @visibleForTesting
  static Map<String, dynamic> options(String token) => io.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .disableReconnection()
      .enableForceNew()
      .setAuth({'token': token})
      .build();

  @override
  void on(String event, void Function(dynamic data) handler) =>
      _socket.on(event, handler);

  @override
  void onConnectError(void Function(dynamic error) handler) =>
      _socket.onConnectError(handler);

  @override
  void onDisconnect(void Function(dynamic reason) handler) =>
      _socket.onDisconnect(handler);

  @override
  void connect() => _socket.connect();

  @override
  void dispose() => _socket.dispose();
}

/// Implémentation réelle de [RealtimeConnection].
///
/// - seuls les événements connus sont transmis ; leur contenu n'est pas lu
///   (l'app relit ses compteurs par l'API) ;
/// - une ancienne connexion (remplacée ou fermée) ne signale plus rien.
class SocketIoRealtimeConnection implements RealtimeConnection {
  new(this._baseUrl, {this._openSocket = SocketIoSocket.new});

  /// Raison donnée par socket_io_client quand le serveur ferme la connexion.
  static const serverDisconnect = 'io server disconnect';

  final Uri _baseUrl;
  final RealtimeSocketFactory _openSocket;
  RealtimeSocket? _socket;
  final _events = StreamController<RealtimeEvent>.broadcast();
  final _closures = StreamController<RealtimeClosure>.broadcast();

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Stream<RealtimeClosure> get closures => _closures.stream;

  @override
  void connect({required String token}) {
    disconnect();
    final socket = _openSocket(_baseUrl, token);
    _socket = socket;
    for (final event in RealtimeEvent.values) {
      socket.on(event.wireName, (_) => _received(socket, event));
    }
    socket
      ..onConnectError((_) => _closed(socket, RealtimeClosure.byServer))
      ..onDisconnect((reason) {
        _closed(
          socket,
          reason == serverDisconnect
              ? RealtimeClosure.byServer
              : RealtimeClosure.network,
        );
      })
      ..connect();
  }

  void _received(RealtimeSocket socket, RealtimeEvent event) {
    if (identical(socket, _socket)) _events.add(event);
  }

  void _closed(RealtimeSocket socket, RealtimeClosure closure) {
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
