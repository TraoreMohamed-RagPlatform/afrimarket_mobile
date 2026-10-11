import 'dart:typed_data';

import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/network/interceptors/app_check_interceptor.dart';
import 'package:afrimarket_mobile/core/security/app_attestation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fausse attestation : renvoie un jeton différent à chaque appel
/// (comme les jetons à usage unique de Firebase).
class _FakeAttestation implements AppAttestation {
  new({this.available = true});

  final bool available;
  int calls = 0;

  @override
  Future<String?> limitedUseToken() async {
    calls++;
    return available ? 'APP-CHECK-$calls' : null;
  }
}

/// Faux serveur : mémorise la dernière requête reçue.
class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final apiBaseUrl = Uri.parse('https://api.example.com');

  late _FakeAttestation attestation;
  late _CaptureAdapter adapter;
  late Dio dio;

  Dio buildDio(_FakeAttestation fake) {
    return Dio(BaseOptions(baseUrl: apiBaseUrl.toString()))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        AppCheckInterceptor(attestation: fake, apiBaseUrl: apiBaseUrl),
      );
  }

  setUp(() {
    attestation = _FakeAttestation();
    adapter = _CaptureAdapter();
    dio = buildDio(attestation);
  });

  String? appCheckHeader() =>
      adapter.lastRequest?.headers[AppCheckInterceptor.headerName] as String?;

  group('AppCheckInterceptor', () {
    test('routes sensibles : jeton App Check ajouté', () async {
      for (final route in ApiEndpoints.attestedRoutes) {
        await dio.post<void>(route);

        expect(appCheckHeader(), startsWith('APP-CHECK-'), reason: route);
      }
    });

    test('un nouveau jeton pour chaque requête (usage unique)', () async {
      await dio.post<void>(ApiEndpoints.login);
      final first = appCheckHeader();
      await dio.post<void>(ApiEndpoints.login);

      expect(appCheckHeader(), isNot(first));
      expect(attestation.calls, 2);
    });

    test('autres routes : aucun jeton demandé ni envoyé', () async {
      await dio.get<void>(ApiEndpoints.me);
      await dio.post<void>(ApiEndpoints.refreshToken);

      expect(appCheckHeader(), isNull);
      expect(attestation.calls, 0);
    });

    test('serveur tiers : le jeton ne part jamais', () async {
      await dio.post<void>('https://evil.example.com${ApiEndpoints.login}');

      expect(appCheckHeader(), isNull);
      expect(attestation.calls, 0);
    });

    test('même chemin en HTTP : pas de jeton', () async {
      await dio.post<void>('http://api.example.com${ApiEndpoints.login}');

      expect(appCheckHeader(), isNull);
    });

    test('sans attestation : requête envoyée sans en-tête', () async {
      dio = buildDio(_FakeAttestation(available: false));

      await dio.post<void>(ApiEndpoints.login);

      expect(adapter.lastRequest, isNotNull);
      expect(appCheckHeader(), isNull);
    });
  });

  group('NoAppAttestation', () {
    test('ne fournit jamais de jeton', () async {
      expect(await const NoAppAttestation().limitedUseToken(), isNull);
    });
  });
}
