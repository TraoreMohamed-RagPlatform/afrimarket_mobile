import 'package:afrimarket_mobile/core/network/network_providers.dart';
import 'package:afrimarket_mobile/features/listings/data/datasources/listings_remote_datasource.dart';
import 'package:afrimarket_mobile/features/listings/data/repositories/listings_repository_impl.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listings_repository.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/get_categories_usecase.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/get_feed_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injection de la fonctionnalité « listings ».
///
/// SEUL fichier qui relie la couche data au domaine. La présentation
/// n'utilise que les cas d'usage.

final listingsRemoteDataSourceProvider = Provider<ListingsRemoteDataSource>(
  (ref) => ListingsRemoteDataSource(ref.watch(dioProvider)),
);

final listingsRepositoryProvider = Provider<ListingsRepository>(
  (ref) => ListingsRepositoryImpl(ref.watch(listingsRemoteDataSourceProvider)),
);

final getFeedUseCaseProvider = Provider<GetFeedUseCase>(
  (ref) => GetFeedUseCase(ref.watch(listingsRepositoryProvider)),
);

final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>(
  (ref) => GetCategoriesUseCase(ref.watch(listingsRepositoryProvider)),
);
