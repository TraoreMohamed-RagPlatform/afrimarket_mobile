import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Faux backend pour Dio : réponses en file (une par requête), requêtes
/// mémorisées. Quand la file est vide, la dernière réponse est reprise.
class FakeHttpServer implements HttpClientAdapter {
  final _responses = <(int, Object?)>[(200, <String, dynamic>{})];
  final requests = <RequestOptions>[];

  /// Réponses des prochaines requêtes, dans l'ordre.
  void respond(List<(int status, Object? body)> responses) {
    _responses
      ..clear()
      ..addAll(responses);
  }

  /// Client Dio branché sur ce faux serveur.
  Dio client() =>
      Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = _responses.length > 1
        ? _responses.removeAt(0)
        : _responses.first;
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
