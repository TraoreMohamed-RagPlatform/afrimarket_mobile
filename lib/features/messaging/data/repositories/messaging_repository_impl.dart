import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/network/api_guard.dart';
import 'package:afrimarket_mobile/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:afrimarket_mobile/features/messaging/domain/repositories/messaging_repository.dart';

/// Implémentation du contrat [MessagingRepository].
class MessagingRepositoryImpl implements MessagingRepository {
  const new(this._remote);

  final MessagingRemoteDataSource _remote;

  @override
  Future<Result<void>> messageSeller({
    required String listingId,
    required String message,
  }) {
    return guardApiCall(
      () => _remote.messageSeller(listingId: listingId, message: message),
    );
  }
}
