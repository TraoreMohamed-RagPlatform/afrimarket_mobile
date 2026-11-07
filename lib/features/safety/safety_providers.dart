import 'package:afrimarket_mobile/core/network/network_providers.dart';
import 'package:afrimarket_mobile/features/safety/data/datasources/safety_remote_datasource.dart';
import 'package:afrimarket_mobile/features/safety/data/repositories/safety_repository_impl.dart';
import 'package:afrimarket_mobile/features/safety/domain/repositories/safety_repository.dart';
import 'package:afrimarket_mobile/features/safety/domain/usecases/safety_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injection de la fonctionnalité « sécurité » (bloquer, signaler).
///
/// SEUL fichier qui relie la couche data au domaine.

final safetyRemoteDataSourceProvider = Provider<SafetyRemoteDataSource>(
  (ref) => SafetyRemoteDataSource(ref.watch(dioProvider)),
);

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => SafetyRepositoryImpl(ref.watch(safetyRemoteDataSourceProvider)),
);

final safetyUseCasesProvider = Provider<SafetyUseCases>(
  (ref) => SafetyUseCases(ref.watch(safetyRepositoryProvider)),
);
