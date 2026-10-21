import 'package:afrimarket_mobile/core/config/app_config.dart';
import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/config/flavor.dart';
import 'package:afrimarket_mobile/core/realtime/realtime_connection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Faux socket : les tests déclenchent eux-mêmes les événements.
class _FakeSocket implements RealtimeSocket {
  new(this.baseUrl, this.token);

  final Uri baseUrl;
  final String token;
  final handlers = <String, void Function(dynamic)>{};
  bool connected = false;
  int disposes = 0;

  @override
  void on(String event, void Function(dynamic data) handler) =>
      handlers[event] = handler;

  @override
  void onConnectError(void Function(dynamic error) handler) =>
      handlers['connect_error'] = handler;

  @override
  void onDisconnect(void Function(dynamic reason) handler) =>
      handlers['disconnect'] = handler;

  @override
  void connect() => connected = true;

  @override
  void dispose() => disposes++;

  /// Le serveur (ou socket_io_client) déclenche [event].
  void fire(String event, [Object? data]) => handlers[event]!(data);
}

/// Laisse passer les événements en attente des flux.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  final baseUrl = Uri.parse('https://api.example.com');
  late List<_FakeSocket> sockets;
  late SocketIoRealtimeConnection connection;
  late List<RealtimeEvent> events;
  late List<RealtimeClosure> closures;

  setUp(() {
    sockets = [];
    connection = SocketIoRealtimeConnection(
      baseUrl,
      openSocket: (url, token) {
        final socket = _FakeSocket(url, token);
        sockets.add(socket);
        return socket;
      },
    );
    events = [];
    closures = [];
    connection.events.listen(events.add);
    connection.closures.listen(closures.add);
  });

  group('SocketIoRealtimeConnection', () {
    test('connexion : adresse de l’API, jeton, connecté', () {
      connection.connect(token: 'jeton-1');

      expect(sockets, hasLength(1));
      expect(sockets.single.baseUrl, baseUrl);
      expect(sockets.single.token, 'jeton-1');
      expect(sockets.single.connected, isTrue);
    });

    test('écoute seulement les événements connus', () {
      connection.connect(token: 'jeton');

      expect(sockets.single.handlers.keys, {
        'notification:new',
        'message:new',
        'connect_error',
        'disconnect',
      });
    });

    test('événements reçus transmis', () async {
      connection.connect(token: 'jeton');

      sockets.single
        ..fire('message:new', {'ignoré': true})
        ..fire('notification:new');
      await _flush();

      expect(events, [RealtimeEvent.message, RealtimeEvent.notification]);
    });

    test('connexion refusée : fermée par le serveur, socket libéré', () async {
      connection.connect(token: 'jeton');

      sockets.single.fire('connect_error', 'unauthorized');
      await _flush();

      expect(closures, [RealtimeClosure.byServer]);
      expect(sockets.single.disposes, 1);
    });

    test('coupée par le serveur : byServer', () async {
      connection.connect(token: 'jeton');

      sockets.single.fire(
        'disconnect',
        SocketIoRealtimeConnection.serverDisconnect,
      );
      await _flush();

      expect(closures, [RealtimeClosure.byServer]);
    });

    test('réseau perdu : network', () async {
      connection.connect(token: 'jeton');

      sockets.single.fire('disconnect', 'transport close');
      await _flush();

      expect(closures, [RealtimeClosure.network]);
    });

    test('nouvelle connexion : l’ancienne est libérée et se tait', () async {
      connection
        ..connect(token: 'ancien')
        ..connect(token: 'neuf');
      final old = sockets.first;

      expect(old.disposes, 1);
      expect(sockets.last.token, 'neuf');

      old
        ..fire('message:new')
        ..fire('disconnect', 'transport close');
      await _flush();

      expect(events, isEmpty);
      expect(closures, isEmpty);
    });

    test('déconnexion : socket libéré, plus aucun signal', () async {
      connection.connect(token: 'jeton');
      final socket = sockets.single;

      connection
        ..disconnect()
        ..disconnect();
      socket
        ..fire('notification:new')
        ..fire('disconnect', 'io client disconnect');
      await _flush();

      expect(socket.disposes, 1);
      expect(events, isEmpty);
      expect(closures, isEmpty);
    });

    test('déconnexion sans connexion : sans effet', () {
      connection.disconnect();

      expect(sockets, isEmpty);
    });
  });

  group('SocketIoSocket', () {
    test('options : jeton dans auth, WebSocket seul, sans reconnexion', () {
      final options = SocketIoSocket.options('jeton');

      expect(options['auth'], {'token': 'jeton'});
      expect(options['transports'], ['websocket']);
      expect(options['autoConnect'], isFalse);
      expect(options['reconnection'], isFalse);
      expect(options.toString(), isNot(contains('query')));
    });

    test('créé, écouté et libéré sans ouvrir de connexion', () {
      SocketIoSocket(Uri.parse('http://127.0.0.1:9'), 'jeton')
        ..on('message:new', (_) {})
        ..onConnectError((_) {})
        ..onDisconnect((_) {})
        ..dispose();
    });
  });

  test('realtimeConnectionProvider : adresse de l’API de la config', () {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.fromValues(
            expected: Flavor.dev,
            flavorName: Flavor.dev.name,
            appName: 'AfriMarket',
            apiBaseUrl: 'http://10.0.2.2:3000',
            enableNetworkLogs: false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(realtimeConnectionProvider),
      isA<SocketIoRealtimeConnection>(),
    );
  });
}
