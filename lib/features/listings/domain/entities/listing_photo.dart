import 'package:meta/meta.dart';

/// Photo d'une annonce dans le formulaire (Publier, Modifier).
///
/// - [LocalPhoto] : choisie sur le téléphone, pas encore envoyée ;
/// - [RemotePhoto] : déjà en ligne (modification d'une annonce).
@immutable
sealed class DraftPhoto {
  const new();

  /// Identifiant stable dans la liste (clé des vignettes).
  String get key;
}

/// Photo choisie sur le téléphone, pas encore envoyée.
final class LocalPhoto extends DraftPhoto {
  const new(this.path);

  /// Chemin du fichier sur le téléphone.
  final String path;

  @override
  String get key => 'local:$path';

  @override
  bool operator ==(Object other) => other is LocalPhoto && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

/// Photo déjà en ligne : identifiant (pour la retirer ou la déplacer) et
/// adresse (pour l'afficher).
final class RemotePhoto extends DraftPhoto {
  const new({required this.id, required this.url});

  final String id;
  final String url;

  @override
  String get key => 'remote:$id';

  @override
  bool operator ==(Object other) =>
      other is RemotePhoto && other.id == id && other.url == url;

  @override
  int get hashCode => Object.hash(id, url);
}
