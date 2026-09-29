import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/network/dio_client.dart';
import 'package:afrimarket_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:afrimarket_mobile/core/network/interceptors/refresh_token_interceptor.dart';
import 'package:afrimarket_mobile/core/network/interceptors/safe_log_interceptor.dart';
import 'package:afrimarket_mobile/core/network/session_expiry.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Client réservé au refresh du token : AUCUN intercepteur,
/// pour qu'il ne puisse jamais se déclencher lui-même.
final refreshDioProvider = Provider<Dio>((ref) {
  final dio = createDio(ref.watch(appConfigProvider));
  ref.onDispose(dio.close);
  return dio;
});

/// Client HTTP de l'application, utilisé par toutes les fonctionnalités.
///
/// Ordre des intercepteurs :
/// 1. SafeLogInterceptor (dev uniquement) : voit tout, y compris les 401 ;
/// 2. AuthInterceptor : ajoute le token ;
/// 3. RefreshTokenInterceptor : renouvelle le token sur 401.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = createDio(config);

  dio.interceptors.addAll([
    if (config.networkLogsEnabled) SafeLogInterceptor(),
    AuthInterceptor(tokenStorage: tokenStorage, apiBaseUrl: config.apiBaseUrl),
    RefreshTokenInterceptor(
      dio: dio,
      refreshDio: ref.watch(refreshDioProvider),
      tokenStorage: tokenStorage,
      apiBaseUrl: config.apiBaseUrl,
      onSessionExpired: () => ref.read(sessionExpiryProvider.notifier).notify(),
    ),
  ]);

  ref.onDispose(dio.close);
  return dio;
});
