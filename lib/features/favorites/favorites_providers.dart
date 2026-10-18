import 'package:afrimarket_mobile/core/network/network_providers.dart';
import 'package:afrimarket_mobile/features/favorites/data/datasources/favorites_remote_datasource.dart';
import 'package:afrimarket_mobile/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:afrimarket_mobile/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:afrimarket_mobile/features/favorites/domain/usecases/get_favorite_status_usecase.dart';
import 'package:afrimarket_mobile/features/favorites/domain/usecases/set_favorite_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injection de la fonctionnalité « favoris ».
///
/// SEUL fichier qui relie la couche data au domaine. Les autres
/// fonctionnalités n'utilisent que les cas d'usage.

final favoritesRemoteDataSourceProvider = Provider<FavoritesRemoteDataSource>(
  (ref) => FavoritesRemoteDataSource(ref.watch(dioProvider)),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) =>
      FavoritesRepositoryImpl(ref.watch(favoritesRemoteDataSourceProvider)),
);

final getFavoriteStatusUseCaseProvider = Provider<GetFavoriteStatusUseCase>(
  (ref) => GetFavoriteStatusUseCase(ref.watch(favoritesRepositoryProvider)),
);

final setFavoriteUseCaseProvider = Provider<SetFavoriteUseCase>(
  (ref) => SetFavoriteUseCase(ref.watch(favoritesRepositoryProvider)),
);
