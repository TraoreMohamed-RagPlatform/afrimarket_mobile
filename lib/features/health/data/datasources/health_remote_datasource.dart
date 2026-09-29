import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:afrimarket_mobile/features/health/data/models/health_status_model.dart';
import 'package:dio/dio.dart';

/// Source distante : `GET /api/health`.
class HealthRemoteDataSource {
  const new(this._dio);

  /// Un test de santé doit répondre vite.
  static const timeout = Duration(seconds: 5);

  final Dio _dio;

  Future<HealthStatusModel> fetch() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.health,
      options: Options(
        receiveTimeout: timeout,
        // Route publique : aucun token n'est envoyé (moindre privilège).
        extra: {AuthInterceptor.skipAuthKey: true},
      ),
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Réponse vide');
    }
    return HealthStatusModel.fromJson(data);
  }
}
