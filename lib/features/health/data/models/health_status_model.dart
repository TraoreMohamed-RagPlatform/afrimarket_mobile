import 'package:afrimarket_mobile/features/health/domain/entities/health_status.dart';

/// DTO : réponse JSON de `GET /api/health`.
///
/// Sécurité : les types sont VALIDÉS. Une réponse inattendue lève une
/// [FormatException], convertie en `UnexpectedFailure` par guardApiCall.
class HealthStatusModel {
  const new({
    required this.status,
    required this.database,
    required this.websocket,
  });

  factory fromJson(Map<String, dynamic> json) {
    return HealthStatusModel(
      status: _requireString(json, 'status'),
      database: _requireString(json, 'database'),
      websocket: _requireString(json, 'websocket'),
    );
  }

  final String status;
  final String database;
  final String websocket;

  HealthStatus toEntity() {
    return HealthStatus(
      status: status,
      database: database,
      websocket: websocket,
    );
  }

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Champ « $key » manquant ou invalide');
    }
    return value;
  }
}
