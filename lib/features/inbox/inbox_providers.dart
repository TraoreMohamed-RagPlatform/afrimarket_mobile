import 'package:afrimarket_mobile/core/network/network_providers.dart';
import 'package:afrimarket_mobile/features/inbox/data/unread_counts_repository_impl.dart';
import 'package:afrimarket_mobile/features/inbox/domain/repositories/unread_counts_repository.dart';
import 'package:afrimarket_mobile/features/inbox/domain/usecases/get_unread_counts_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injection de la fonctionnalité « inbox » (compteurs de non-lus).

final unreadCountsRepositoryProvider = Provider<UnreadCountsRepository>(
  (ref) => UnreadCountsRepositoryImpl(ref.watch(dioProvider)),
);

final getUnreadCountsUseCaseProvider = Provider<GetUnreadCountsUseCase>(
  (ref) => GetUnreadCountsUseCase(ref.watch(unreadCountsRepositoryProvider)),
);
