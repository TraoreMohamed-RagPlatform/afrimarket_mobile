import 'package:afrimarket_mobile/core/storage/secure_storage.dart';
import 'package:afrimarket_mobile/core/storage/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stockage chiffré, partagé par toute l'application.
final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

/// Gestion des tokens JWT.
///
/// UNE SEULE instance pour toute l'app : l'access token est gardé en
/// mémoire, deux instances pourraient donc avoir des états différents
/// (par exemple l'une déconnectée, l'autre encore authentifiée).
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageProvider)),
);
