import 'package:afrimarket_mobile/core/network/network_providers.dart';
import 'package:afrimarket_mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:afrimarket_mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:afrimarket_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:afrimarket_mobile/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injection de la fonctionnalité « notifications ».
///
/// SEUL fichier qui relie la couche data au domaine.

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>(
      (ref) => NotificationsRemoteDataSource(ref.watch(dioProvider)),
    );

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(
    ref.watch(notificationsRemoteDataSourceProvider),
  ),
);

final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>(
  (ref) => GetNotificationsUseCase(ref.watch(notificationsRepositoryProvider)),
);

final manageNotificationsUseCaseProvider = Provider<ManageNotificationsUseCase>(
  (ref) =>
      ManageNotificationsUseCase(ref.watch(notificationsRepositoryProvider)),
);
