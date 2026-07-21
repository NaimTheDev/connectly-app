import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Handles reading and writing user files in Firebase Storage.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const _profileImagesFolder = 'profile_images';

  Reference _profileRef(String uid) =>
      _storage.ref().child('$_profileImagesFolder/$uid.jpg');

  /// Uploads [file] to `profile_images/{uid}.jpg` and returns its download URL.
  ///
  /// The path is deterministic so a re-upload overwrites the previous image in
  /// place (no orphaned files). The returned URL carries a fresh token, so
  /// `NetworkImage` will not serve a stale cached image.
  ///
  /// Takes raw [bytes] and uploads via `putData` rather than `putFile` so this
  /// works on web, where `dart:io`'s `File` is unavailable.
  Future<String> uploadProfileImage(String uid, Uint8List bytes) async {
    final ref = _profileRef(uid);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Deletes the current profile image. No-op if the object does not exist.
  Future<void> deleteProfileImage(String uid) async {
    try {
      await _profileRef(uid).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      rethrow;
    }
  }
}
