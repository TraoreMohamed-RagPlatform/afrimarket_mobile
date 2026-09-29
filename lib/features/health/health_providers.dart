import 'package:afrimarket_mobile/core/network/network_providers.dart';
import 'package:afrimarket_mobile/features/health/data/datasources/health_remote_datasource.dart';
import 'package:afrimarket_mobile/features/health/data/repositories/health_repository_impl.dart';
import 'package:afrimarket_mobile/features/health/domain/repositories/health_repository.dart';
import 'package:afrimarket_mobile/features/health/domain/usecases/check_health_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injection de la fonctionnalité « health ».
///
/// SEUL fichier qui relie la couche data au domaine. La présentation
/// n'utilise que [checkHealthUseCaseProvider].

final healthRemoteDataSourceProvider = Provider<HealthRemoteDataSource>(
  (ref) => HealthRemoteDataSource(ref.watch(dioProvider)),
);

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepositoryImpl(ref.watch(healthRemoteDataSourceProvider)),
);

final checkHealthUseCaseProvider = Provider<CheckHealthUseCase>(
  (ref) => CheckHealthUseCase(ref.watch(healthRepositoryProvider)),
);
