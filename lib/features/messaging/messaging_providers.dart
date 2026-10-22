import 'package:afrimarket_mobile/core/network/network_providers.dart';
import 'package:afrimarket_mobile/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:afrimarket_mobile/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:afrimarket_mobile/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:afrimarket_mobile/features/messaging/domain/usecases/conversation_usecases.dart';
import 'package:afrimarket_mobile/features/messaging/domain/usecases/message_seller_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injection de la fonctionnalité « messagerie ».
///
/// SEUL fichier qui relie la couche data au domaine. Les autres
/// fonctionnalités n'utilisent que les cas d'usage.

final messagingRemoteDataSourceProvider = Provider<MessagingRemoteDataSource>(
  (ref) => MessagingRemoteDataSource(ref.watch(dioProvider)),
);

final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) =>
      MessagingRepositoryImpl(ref.watch(messagingRemoteDataSourceProvider)),
);

final messageSellerUseCaseProvider = Provider<MessageSellerUseCase>(
  (ref) => MessageSellerUseCase(ref.watch(messagingRepositoryProvider)),
);

final getConversationsUseCaseProvider = Provider<GetConversationsUseCase>(
  (ref) => GetConversationsUseCase(ref.watch(messagingRepositoryProvider)),
);

final getConversationUseCaseProvider = Provider<GetConversationUseCase>(
  (ref) => GetConversationUseCase(ref.watch(messagingRepositoryProvider)),
);

final getMessagesUseCaseProvider = Provider<GetMessagesUseCase>(
  (ref) => GetMessagesUseCase(ref.watch(messagingRepositoryProvider)),
);

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>(
  (ref) => SendMessageUseCase(ref.watch(messagingRepositoryProvider)),
);
