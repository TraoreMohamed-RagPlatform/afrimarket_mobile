import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Choix de photos sur le téléphone (galerie ou appareil photo).
///
/// Interface séparée : les tests la remplacent par un faux, sans ouvrir
/// la galerie.
abstract interface class PhotoPicker {
  /// Photos choisies dans la galerie, [limit] au plus.
  ///
  /// Liste vide : l'utilisateur a annulé. `null` : accès refusé ou
  /// galerie indisponible.
  Future<List<String>?> pickFromGallery({required int limit});

  /// Photo prise avec l'appareil photo.
  ///
  /// `null` avec [PhotoPickError.none] : annulé ; sinon l'erreur.
  Future<(String?, PhotoPickError)> takePhoto();
}

/// Pourquoi aucune photo n'a été obtenue.
enum PhotoPickError { none, unavailable }

/// Implémentation réelle (image_picker).
///
/// Économie de données et vie privée :
/// - photos réduites à 1600 px et recompressées en JPEG sur le téléphone,
///   avant tout envoi ;
/// - métadonnées complètes non demandées (le serveur retire aussi
///   EXIF et position GPS).
class PlatformPhotoPicker implements PhotoPicker {
  new([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  static const double maxDimension = 1600;
  static const int quality = 85;

  final ImagePicker _picker;

  @override
  Future<List<String>?> pickFromGallery({required int limit}) async {
    if (limit < 1) return const [];
    try {
      // `limit` doit valoir au moins 2 pour pickMultiImage.
      final files = limit == 1
          ? [
              ?await _picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: maxDimension,
                maxHeight: maxDimension,
                imageQuality: quality,
                requestFullMetadata: false,
              ),
            ]
          : await _picker.pickMultiImage(
              maxWidth: maxDimension,
              maxHeight: maxDimension,
              imageQuality: quality,
              limit: limit,
              requestFullMetadata: false,
            );
      return [for (final file in files.take(limit)) file.path];
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<(String?, PhotoPickError)> takePhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        imageQuality: quality,
        requestFullMetadata: false,
      );
      return (file?.path, PhotoPickError.none);
    } on PlatformException {
      return (null, PhotoPickError.unavailable);
    }
  }
}

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => PlatformPhotoPicker(),
);
