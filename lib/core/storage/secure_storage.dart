import 'package:afrimarket_mobile/core/error/failure.dart';
import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage chiffré clé / valeur de l'application.
///
/// Point d'accès UNIQUE au stockage sécurisé : le reste de l'app
/// n'importe jamais `flutter_secure_storage` directement.
///
/// Sécurité (OWASP MASVS - STORAGE) :
/// - Android : chiffrement RSA OAEP + AES-GCM, clé dans l'Android Keystore
///   (configuration par défaut recommandée depuis la version 10) ;
/// - iOS : Keychain, accessible après le premier déverrouillage et
///   uniquement sur CET appareil (jamais transféré par une sauvegarde) ;
/// - la sauvegarde Android est désactivée (allowBackup="false").
///
/// Toute erreur technique est convertie en [StorageFailure].
class SecureStorage {
  new([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  /// Lit la valeur associée à [key] (null si absente).
  Future<Result<String?>> read(String key) async {
    try {
      return Ok(await _storage.read(key: key));
    } on Exception {
      return const Err(StorageFailure());
    }
  }

  /// Enregistre [value] sous la clé [key].
  Future<Result<void>> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
      return const Ok(null);
    } on Exception {
      return const Err(StorageFailure());
    }
  }

  /// Supprime la valeur associée à [key].
  Future<Result<void>> delete(String key) async {
    try {
      await _storage.delete(key: key);
      return const Ok(null);
    } on Exception {
      return const Err(StorageFailure());
    }
  }

  /// Supprime toutes les valeurs (ex. : déconnexion complète).
  Future<Result<void>> deleteAll() async {
    try {
      await _storage.deleteAll();
      return const Ok(null);
    } on Exception {
      return const Err(StorageFailure());
    }
  }
}
