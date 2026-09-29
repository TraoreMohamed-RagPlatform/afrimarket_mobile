import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/error_mapper.dart';
import 'package:dio/dio.dart';

/// Exécute un appel API et renvoie un [Result] au lieu de lever
/// des exceptions.
///
/// À utiliser dans TOUTES les sources de données distantes :
/// ```dart
/// Future<Result<User>> me() => guardApiCall(() async {
///   final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
///   return User.fromJson(response.data!);
/// });
/// ```
Future<Result<T>> guardApiCall<T>(Future<T> Function() call) async {
  try {
    return Ok(await call());
  } on DioException catch (exception) {
    return Err(mapDioException(exception));
  } on Object {
    // Réponse inattendue (JSON malformé, champ manquant...) : l'app ne
    // doit jamais planter ni afficher de détail technique.
    return const Err(UnexpectedFailure());
  }
}
