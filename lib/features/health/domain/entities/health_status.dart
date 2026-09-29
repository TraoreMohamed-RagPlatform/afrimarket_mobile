import 'package:meta/meta.dart';

/// État de santé du serveur AfriMarket.
///
/// Entité métier : Dart pur, sans dépendance à Flutter ni à l'API.
@immutable
final class HealthStatus {
  const new({
    required this.status,
    required this.database,
    required this.websocket,
  });

  final String status;
  final String database;
  final String websocket;

  /// Le serveur est considéré en bonne santé si son statut est « ok ».
  bool get isHealthy => status == 'ok';

  @override
  bool operator ==(Object other) =>
      other is HealthStatus &&
      other.status == status &&
      other.database == database &&
      other.websocket == websocket;

  @override
  int get hashCode => Object.hash(status, database, websocket);
}
