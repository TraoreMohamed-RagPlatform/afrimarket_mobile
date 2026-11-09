import 'dart:async';

import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/pagination/cursor_page.dart';
import 'package:afrimarket_mobile/core/platform/photo_picker.dart';
import 'package:afrimarket_mobile/core/realtime/realtime_connection.dart';
import 'package:afrimarket_mobile/features/inbox/presentation/unread_counts_controller.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/chat_message.dart';
import 'package:afrimarket_mobile/features/messaging/domain/entities/conversation.dart';
import 'package:afrimarket_mobile/features/messaging/domain/message_rules.dart';
import 'package:afrimarket_mobile/features/messaging/messaging_providers.dart';
import 'package:afrimarket_mobile/features/messaging/presentation/controllers/conversations_controller.dart';
import 'package:afrimarket_mobile/features/safety/domain/entities/person_report_reason.dart';
import 'package:afrimarket_mobile/features/safety/domain/usecases/safety_usecases.dart';
import 'package:afrimarket_mobile/features/safety/safety_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:meta/meta.dart';

/// D'où vient une photo à envoyer.
enum ChatPhotoSource { camera, gallery }

/// Résultat du choix de photos à envoyer.
enum ChatPhotoOutcome {
  /// Photos choisies : envoi en cours.
  sending,

  /// Rien de choisi.
  cancelled,

  /// Galerie ou appareil photo inaccessible (autorisation refusée...).
  unavailable,
}

/// Message écrit ici, pas encore confirmé par le serveur : un texte ou
/// une photo ([photoPath], fichier du téléphone).
@immutable
final class PendingMessage {
  const new({
    required this.localId,
    required this.text,
    required this.createdAt,
    this.photoPath,
    this.failed = false,
  });

  final int localId;

  /// Texte ; vide pour une photo.
  final String text;

  /// Photo à envoyer, si c'en est une.
  final String? photoPath;

  final DateTime createdAt;

  /// L'envoi a échoué : « Non envoyé. Touchez pour réessayer. »
  final bool failed;

  PendingMessage withFailed({required bool failed}) => PendingMessage(
    localId: localId,
    text: text,
    photoPath: photoPath,
    createdAt: createdAt,
    failed: failed,
  );
}

/// Une discussion ouverte.
@immutable
final class ChatState {
  const new({
    this.phase = ListPhase.loading,
    this.header,
    this.messages = const [],
    this.pending = const [],
    this.sentPhotoFiles = const {},
    this.nextCursor,
    this.isLoadingOlder = false,
    this.failure,
    this.olderFailure,
    this.sendFailure,
  });

  final ListPhase phase;

  /// Annonce et autre personne.
  final ConversationSummary? header;

  /// Messages confirmés, les plus récents d'abord.
  final List<ChatMessage> messages;

  /// Messages en cours d'envoi ou non envoyés, du plus ancien au plus
  /// récent.
  final List<PendingMessage> pending;

  /// Photos que je viens d'envoyer : identifiant du message → fichier du
  /// téléphone (affiché sans la télécharger à nouveau).
  final Map<String, String> sentPhotoFiles;

  /// Messages plus anciens à charger.
  final String? nextCursor;
  final bool isLoadingOlder;

  final Failure? failure;
  final Failure? olderFailure;

  /// Dernier échec d'envoi (message à afficher une fois).
  final Failure? sendFailure;

  bool get canLoadOlder =>
      phase == ListPhase.ready &&
      nextCursor != null &&
      !isLoadingOlder &&
      olderFailure == null;

  bool get canSend => header?.otherUser.canReceiveMessages ?? true;

  ChatState copyWith({
    ListPhase? phase,
    ConversationSummary? header,
    List<ChatMessage>? messages,
    List<PendingMessage>? pending,
    Map<String, String>? sentPhotoFiles,
    String? Function()? nextCursor,
    bool? isLoadingOlder,
    Failure? Function()? failure,
    Failure? Function()? olderFailure,
    Failure? Function()? sendFailure,
  }) {
    return ChatState(
      phase: phase ?? this.phase,
      header: header ?? this.header,
      messages: messages ?? this.messages,
      pending: pending ?? this.pending,
      sentPhotoFiles: sentPhotoFiles ?? this.sentPhotoFiles,
      nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      failure: failure == null ? this.failure : failure(),
      olderFailure: olderFailure == null ? this.olderFailure : olderFailure(),
      sendFailure: sendFailure == null ? this.sendFailure : sendFailure(),
    );
  }
}

/// Pilote une discussion : en-tête, messages (page par page), envoi
/// affiché tout de suite puis confirmé, nouveaux messages en temps réel.
class ChatController extends Notifier<ChatState> {
  new(this.conversationId);

  final String conversationId;

  int _nextLocalId = 0;

  /// Envois de photos, l'un après l'autre (l'ordre choisi est gardé).
  Future<void> _photoDeliveries = Future.value();

  /// Fin des envois de photos en cours (pour les tests).
  @visibleForTesting
  Future<void> get photoDeliveries => _photoDeliveries;

  @override
  ChatState build() {
    final events = ref
        .read(realtimeConnectionProvider)
        .events
        .where((event) => event == RealtimeEvent.message)
        .listen((_) => unawaited(_reloadLatest()));
    ref.onDispose(() => unawaited(events.cancel()));

    unawaited(Future.microtask(_load));
    return const ChatState();
  }

  /// « Réessayer » après un échec du premier chargement.
  Future<void> retry() {
    state = const ChatState();
    return _load();
  }

  /// Messages plus anciens (haut de la discussion).
  Future<void> loadOlder() async {
    final current = state;
    if (!current.canLoadOlder) return;
    state = current.copyWith(isLoadingOlder: true);

    final result = await ref.read(getMessagesUseCaseProvider)(
      conversationId,
      before: current.nextCursor,
    );
    if (!ref.mounted) return;

    switch (result) {
      case Ok(:final value):
        final known = {for (final message in state.messages) message.id};
        state = state.copyWith(
          messages: [
            ...state.messages,
            ...value.items.where((message) => !known.contains(message.id)),
          ],
          nextCursor: () => value.nextCursor,
          isLoadingOlder: false,
        );
      case Err(:final failure):
        state = state.copyWith(
          isLoadingOlder: false,
          olderFailure: () => failure,
        );
    }
  }

  /// « Réessayer » en haut de la discussion.
  Future<void> retryOlder() {
    state = state.copyWith(olderFailure: () => null);
    return loadOlder();
  }

  /// Envoie [text] : affiché tout de suite, confirmé par le serveur.
  /// Vide ou trop long : ignoré (le bouton est désactivé).
  Future<void> send(String text) async {
    final clean = MessageRules.clean(text);
    if (clean == null || !state.canSend) return;
    final pending = PendingMessage(
      localId: _nextLocalId++,
      text: clean,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(pending: [...state.pending, pending]);
    await _deliver(pending);
  }

  /// Choisit des photos ([source]) et les envoie, une par message, dans
  /// l'ordre choisi (10 au plus depuis la galerie). Chacune est affichée
  /// tout de suite, puis confirmée par le serveur.
  Future<ChatPhotoOutcome> sendPhotos(ChatPhotoSource source) async {
    if (!state.canSend) return ChatPhotoOutcome.cancelled;
    final picker = ref.read(photoPickerProvider);
    final List<String>? paths;
    switch (source) {
      case ChatPhotoSource.gallery:
        paths = await picker.pickFromGallery(
          limit: MessageRules.maxPhotosPerPick,
        );
      case ChatPhotoSource.camera:
        final (path, error) = await picker.takePhoto();
        paths = error == PhotoPickError.none ? [?path] : null;
    }
    if (!ref.mounted) return ChatPhotoOutcome.cancelled;
    if (paths == null) return ChatPhotoOutcome.unavailable;
    if (paths.isEmpty) return ChatPhotoOutcome.cancelled;

    final queued = [
      for (final path in paths.take(MessageRules.maxPhotosPerPick))
        PendingMessage(
          localId: _nextLocalId++,
          text: '',
          photoPath: path,
          createdAt: DateTime.now(),
        ),
    ];
    state = state.copyWith(pending: [...state.pending, ...queued]);
    _photoDeliveries = _photoDeliveries.then((_) async {
      for (final item in queued) {
        if (!ref.mounted) return;
        // Retiré entre-temps : rien à envoyer.
        if (_pendingById(item.localId) == null) continue;
        await _deliver(item);
      }
    });
    return ChatPhotoOutcome.sending;
  }

  /// Nouvel essai d'un message non envoyé.
  Future<void> resend(int localId) async {
    final pending = _pendingById(localId);
    if (pending == null || !pending.failed) return;
    _replacePending(pending.withFailed(failed: false));
    await _deliver(pending);
  }

  /// Retire un message non envoyé.
  void discard(int localId) {
    state = state.copyWith(
      pending: [
        for (final item in state.pending)
          if (item.localId != localId) item,
      ],
    );
  }

  /// Bloque l'autre personne ; renvoie l'échec éventuel (null : fait).
  Future<Failure?> block() =>
      _safetyAction((safety, userId) => safety.block(userId));

  /// Débloque l'autre personne ; renvoie l'échec éventuel (null : fait).
  Future<Failure?> unblock() =>
      _safetyAction((safety, userId) => safety.unblock(userId));

  /// Signale l'autre personne depuis cette discussion ; [alsoBlock] : la
  /// bloque ensuite. Renvoie l'échec éventuel (null : fait).
  Future<Failure?> report({
    required PersonReportReason reason,
    String details = '',
    bool alsoBlock = false,
  }) async {
    final header = state.header;
    if (header == null) return null;
    final result = await ref
        .read(safetyUseCasesProvider)
        .report(
          userId: header.otherUser.id,
          reason: reason,
          details: details,
          conversationId: conversationId,
        );
    if (!ref.mounted) return null;
    if (result case Err(:final failure)) return failure;
    if (alsoBlock && !header.blockedByMe) return await block();
    return null;
  }

  Future<Failure?> _safetyAction(
    Future<Result<void>> Function(SafetyUseCases safety, String userId) action,
  ) async {
    final header = state.header;
    if (header == null) return null;
    final result = await action(
      ref.read(safetyUseCasesProvider),
      header.otherUser.id,
    );
    if (!ref.mounted) return null;
    if (result case Err(:final failure)) return failure;
    await _reloadHeader();
    return null;
  }

  /// Relit l'en-tête (blocage, possibilité d'écrire).
  Future<void> _reloadHeader() async {
    final result = await ref.read(getConversationUseCaseProvider)(
      conversationId,
    );
    if (!ref.mounted) return;
    if (result case Ok(:final value)) state = state.copyWith(header: value);
  }

  /// Le message d'échec d'envoi a été affiché.
  void sendFailureShown() => state = state.copyWith(sendFailure: () => null);

  PendingMessage? _pendingById(int localId) {
    for (final item in state.pending) {
      if (item.localId == localId) return item;
    }
    return null;
  }

  void _replacePending(PendingMessage pending) {
    state = state.copyWith(
      pending: [
        for (final item in state.pending)
          if (item.localId == pending.localId) pending else item,
      ],
    );
  }

  Future<void> _deliver(PendingMessage pending) async {
    final photoPath = pending.photoPath;
    final result = photoPath == null
        ? await ref.read(sendMessageUseCaseProvider)(
            conversationId: conversationId,
            text: pending.text,
          )
        : await ref.read(sendPhotoUseCaseProvider)(
            conversationId: conversationId,
            path: photoPath,
          );
    if (!ref.mounted) return;

    switch (result) {
      case Ok(:final value):
        final known = state.messages.any((message) => message.id == value.id);
        state = state.copyWith(
          messages: known ? null : [value, ...state.messages],
          sentPhotoFiles: photoPath == null
              ? null
              : {...state.sentPhotoFiles, value.id: photoPath},
          pending: [
            for (final item in state.pending)
              if (item.localId != pending.localId) item,
          ],
        );
      case Err(:final failure):
        _replacePending(pending.withFailed(failed: true));
        state = state.copyWith(sendFailure: () => failure);
    }
  }

  Future<void> _load() async {
    final results = await (
      ref.read(getConversationUseCaseProvider)(conversationId),
      ref.read(getMessagesUseCaseProvider)(conversationId),
    ).wait;
    if (!ref.mounted) return;

    switch (results) {
      case (Ok(value: final header), Ok(value: final page)):
        state = state.copyWith(
          phase: ListPhase.ready,
          header: header,
          messages: page.items,
          nextCursor: () => page.nextCursor,
        );
        _refreshUnreadCounts();
      case (Err(:final failure), _) || (_, Err(:final failure)):
        state = state.copyWith(phase: ListPhase.failed, failure: () => failure);
    }
  }

  /// Nouveau message reçu : relit les plus récents (et les marque lus).
  Future<void> _reloadLatest() async {
    if (state.phase != ListPhase.ready) return;
    final result = await ref.read(getMessagesUseCaseProvider)(conversationId);
    if (!ref.mounted) return;
    if (result case Ok(:final value)) {
      state = state.copyWith(messages: _merge(value, state.messages));
      _refreshUnreadCounts();
    }
  }

  /// Les plus récents d'abord ; une version relue d'un message (« Vu »)
  /// remplace l'ancienne.
  static List<ChatMessage> _merge(
    CursorPage<ChatMessage> latest,
    List<ChatMessage> current,
  ) {
    final fresh = {for (final message in latest.items) message.id};
    return [
      ...latest.items,
      ...current.where((message) => !fresh.contains(message.id)),
    ];
  }

  void _refreshUnreadCounts() =>
      unawaited(ref.read(unreadCountsProvider.notifier).refresh());
}

/// Une discussion, par identifiant. Libérée en la quittant.
final NotifierProviderFamily<ChatController, ChatState, String>
chatControllerProvider = NotifierProvider.autoDispose
    .family<ChatController, ChatState, String>(ChatController.new);
