import 'package:afrimarket_mobile/core/network/api_endpoints.dart';
import 'package:afrimarket_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:afrimarket_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:dio/dio.dart';

/// Source distante : routes `/api/auth/*` du backend.
///
/// Les preuves App Check (connexion, inscription) et les tokens sont
/// ajoutés par les intercepteurs du client [Dio], jamais ici.
class AuthRemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  /// `POST /api/auth/login`.
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return AuthSessionModel.fromJson(_body(response));
  }

  /// `POST /api/auth/register`.
  Future<AuthSessionModel> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {
        'fullName': fullName,
        'username': username,
        'email': email,
        'password': password,
      },
    );
    return AuthSessionModel.fromJson(_body(response));
  }

  /// `POST /api/auth/forgot-password`.
  Future<void> requestPasswordReset({required String email}) async {
    await _dio.post<void>(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  /// `POST /api/auth/reset-password`.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      ApiEndpoints.resetPassword,
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }

  /// `POST /api/auth/logout` : révoque [refreshToken] côté serveur.
  ///
  /// Sans token d'accès ni refresh automatique (`skipAuth`) : la session
  /// locale est déjà effacée, il ne faut surtout pas la « réparer ».
  Future<void> logout({required String refreshToken}) async {
    await _dio.post<void>(
      ApiEndpoints.logout,
      data: {'refreshToken': refreshToken},
      options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
    );
  }

  static Map<String, dynamic> _body(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) throw const FormatException('Réponse vide');
    return data;
  }
}
