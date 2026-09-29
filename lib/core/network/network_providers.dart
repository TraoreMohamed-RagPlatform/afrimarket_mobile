import 'package:afrimarket_mobile/core/config/app_config_provider.dart';
import 'package:afrimarket_mobile/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Client HTTP de l'application, partagé par toutes les fonctionnalités.
final dioProvider = Provider<Dio>((ref) {
  final dio = createDio(ref.watch(appConfigProvider));
  ref.onDispose(dio.close);
  return dio;
});
