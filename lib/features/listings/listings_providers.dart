import 'package:afrimarket_mobile/core/network/network_providers.dart';
import 'package:afrimarket_mobile/features/listings/data/datasources/listings_remote_datasource.dart';
import 'package:afrimarket_mobile/features/listings/data/repositories/listing_publisher_impl.dart';
import 'package:afrimarket_mobile/features/listings/data/repositories/listings_repository_impl.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listing_publisher.dart';
import 'package:afrimarket_mobile/features/listings/domain/repositories/listings_repository.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/get_categories_usecase.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/get_feed_usecase.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/get_listing_detail_usecase.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/get_listing_locations_usecase.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/get_seller_contact_usecase.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/get_similar_listings_usecase.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/manage_own_listing_usecase.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/publish_listing_usecase.dart';
import 'package:afrimarket_mobile/features/listings/domain/usecases/report_listing_usecase.dart';
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

final getListingDetailUseCaseProvider = Provider<GetListingDetailUseCase>(
  (ref) => GetListingDetailUseCase(ref.watch(listingsRepositoryProvider)),
);

final getSimilarListingsUseCaseProvider = Provider<GetSimilarListingsUseCase>(
  (ref) => GetSimilarListingsUseCase(ref.watch(listingsRepositoryProvider)),
);

final getListingLocationsUseCaseProvider = Provider<GetListingLocationsUseCase>(
  (ref) => GetListingLocationsUseCase(ref.watch(listingsRepositoryProvider)),
);

final getSellerContactUseCaseProvider = Provider<GetSellerContactUseCase>(
  (ref) => GetSellerContactUseCase(ref.watch(listingsRepositoryProvider)),
);

final reportListingUseCaseProvider = Provider<ReportListingUseCase>(
  (ref) => ReportListingUseCase(ref.watch(listingsRepositoryProvider)),
);

final listingPublisherProvider = Provider<ListingPublisher>(
  (ref) => ListingPublisherImpl(ref.watch(dioProvider)),
);

final publishListingUseCaseProvider = Provider<PublishListingUseCase>(
  (ref) => PublishListingUseCase(ref.watch(listingPublisherProvider)),
);

final manageOwnListingUseCaseProvider = Provider<ManageOwnListingUseCase>(
  (ref) => ManageOwnListingUseCase(ref.watch(listingPublisherProvider)),
);
