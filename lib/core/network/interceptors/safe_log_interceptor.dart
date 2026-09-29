import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Journal réseau pour le DÉVELOPPEMENT uniquement.
///
/// Branché seulement si `AppConfig.networkLogsEnabled` est vrai
/// (flavor dev ET build non-release).
///
/// Sécurité (OWASP MASVS - PRIVACY / STORAGE) :
/// - aucun en-tête n'est affiché (Authorization, cookies...) ;
/// - les valeurs des clés sensibles sont masquées à tous les niveaux ;
/// - les paramètres d'URL sensibles sont masqués ;
/// - les formulaires multipart (documents, selfie) ne sont jamais affichés ;
/// - les textes bruts ne sont pas affichés (seulement leur longueur).
class SafeLogInterceptor extends Interceptor {
  new({void Function(String message)? sink}) : _sink = sink ?? _defaultSink;

  static const _startKey = 'safeLogStart';
  static const _maxBodyLength = 1000;
  static const _masked = '***';

  /// Toute clé contenant l'un de ces fragments est masquée.
  static const sensitiveFragments = <String>[
    'password',
    'token',
    'secret',
    'authorization',
    'otp',
    'code',
    'cookie',
    'card',
    'iban',
    'documentnumber',
  ];

  final void Function(String message) _sink;

  static void _defaultSink(String message) {
    developer.log(message, name: 'AfriMarket.network');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    _sink(
      '→ ${options.method} ${_describe(options.uri)}${_body(options.data)}',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    _sink(
      '← ${response.statusCode} ${options.method} ${_describe(options.uri)} '
      '(${_elapsed(options)})${_body(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final status = err.response?.statusCode?.toString() ?? err.type.name;
    _sink(
      '✗ $status ${options.method} ${_describe(options.uri)} '
      '(${_elapsed(options)})${_body(err.response?.data)}',
    );
    handler.next(err);
  }

  /// Masque récursivement les valeurs des clés sensibles.
  static Object? redact(Object? data) {
    if (data is Map) {
      return data.map(
        (key, value) =>
            MapEntry('$key', _isSensitive('$key') ? _masked : redact(value)),
      );
    }
    if (data is List) {
      return data.map(redact).toList();
    }
    return data;
  }

  static bool _isSensitive(String key) {
    final lower = key.toLowerCase();
    return sensitiveFragments.any(lower.contains);
  }

  static String _describe(Uri uri) {
    if (uri.queryParameters.isEmpty) return uri.path;

    final query = uri.queryParameters.entries
        .map((e) => '${e.key}=${_isSensitive(e.key) ? _masked : e.value}')
        .join('&');
    return '${uri.path}?$query';
  }

  static String _elapsed(RequestOptions options) {
    final start = options.extra[_startKey];
    if (start is! DateTime) return '? ms';
    return '${DateTime.now().difference(start).inMilliseconds} ms';
  }

  static String _body(Object? data) {
    if (data == null) return '';

    if (data is FormData) {
      return '\n  [multipart : ${data.fields.length} champ(s), '
          '${data.files.length} fichier(s)]';
    }
    if (data is String) {
      return '\n  [texte : ${data.length} caractère(s)]';
    }

    String text;
    try {
      text = jsonEncode(redact(data));
    } on Object {
      return '\n  [corps non affichable]';
    }

    if (text.length > _maxBodyLength) {
      text = '${text.substring(0, _maxBodyLength)}…';
    }
    return '\n  $text';
  }
}
