import 'package:afrimarket_mobile/core/network/network_providers.dart';
import 'package:afrimarket_mobile/core/storage/storage_providers.dart';
import 'package:afrimarket_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:afrimarket_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:afrimarket_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:afrimarket_mobile/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injection de la fonctionnalité « auth ».
///
/// SEUL fichier qui relie la couche data au domaine. La présentation
/// n'utilise que les cas d'usage.

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(tokenStorageProvider),
  ),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);

final requestPasswordResetUseCaseProvider =
    Provider<RequestPasswordResetUseCase>(
      (ref) => RequestPasswordResetUseCase(ref.watch(authRepositoryProvider)),
    );

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>(
  (ref) => ResetPasswordUseCase(ref.watch(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);
