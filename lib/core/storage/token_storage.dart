import 'package:afrimarket_mobile/core/error/result.dart';
import 'package:afrimarket_mobile/core/storage/secure_storage.dart';

/// Gestion des tokens d'authentification (JWT).
///
/// Sécurité (OWASP MASVS - STORAGE / AUTH) :
/// - tokens stockés uniquement via [SecureStorage] (chiffré) ;
/// - l'access token est gardé en mémoire pour éviter de solliciter le
///   stockage chiffré à chaque requête ;
/// - le refresh token n'est JAMAIS gardé en mémoire ;
/// - enregistrement « tout ou rien » : jamais de session partielle ;
/// - à la déconnexion, la mémoire est vidée avant le stockage.
///
/// Ne jamais afficher ni journaliser la valeur d'un token.
class TokenStorage {
  new(this._storage);

  static const accessTokenKey = 'auth.access_token';
  static const refreshTokenKey = 'auth.refresh_token';

  final SecureStorage _storage;
  String? _cachedAccessToken;

  /// Enregistre les deux tokens (après connexion ou refresh).
  Future<Result<void>> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final accessResult = await _storage.write(
      key: accessTokenKey,
      value: accessToken,
    );
    if (accessResult case Err(:final failure)) {
      return Err(failure);
    }

    final refreshResult = await _storage.write(
      key: refreshTokenKey,
      value: refreshToken,
    );
    if (refreshResult case Err(:final failure)) {
      // Tout ou rien : on ne garde pas une session incomplète.
      _cachedAccessToken = null;
      await _storage.delete(accessTokenKey);
      return Err(failure);
    }

    _cachedAccessToken = accessToken;
    return const Ok(null);
  }

  /// Lit l'access token (depuis la mémoire si disponible).
  Future<Result<String?>> readAccessToken() async {
    final cached = _cachedAccessToken;
    if (cached != null) return Ok(cached);

    final result = await _storage.read(accessTokenKey);
    if (result case Ok(:final value)) {
      _cachedAccessToken = value;
    }
    return result;
  }

  /// Lit le refresh token (toujours depuis le stockage chiffré).
  Future<Result<String?>> readRefreshToken() {
    return _storage.read(refreshTokenKey);
  }

  /// Indique si une session existe (un refresh token est présent).
  Future<Result<bool>> hasTokens() async {
    final result = await readRefreshToken();
    return result.map((token) => token != null && token.isNotEmpty);
  }

  /// Efface les tokens (déconnexion).
  Future<Result<void>> clear() async {
    // La mémoire d'abord : même si le stockage échoue, le token
    // n'est plus utilisable par l'application.
    _cachedAccessToken = null;

    final accessResult = await _storage.delete(accessTokenKey);
    final refreshResult = await _storage.delete(refreshTokenKey);

    return accessResult.isErr ? accessResult : refreshResult;
  }
}
