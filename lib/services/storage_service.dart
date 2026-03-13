import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

/// Storage service for file uploads (avatars, logos, progress photos).
class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  /// Upload an avatar image.
  Future<String> uploadAvatar(
      String userId, List<int> fileBytes, String fileName) async {
    final path = '$userId/$fileName';

    await _client.storage
        .from(AppConstants.avatarsBucket)
        .uploadBinary(path, fileBytes as dynamic);

    return _client.storage.from(AppConstants.avatarsBucket).getPublicUrl(path);
  }

  /// Upload a gym logo.
  Future<String> uploadGymLogo(
      String gymId, List<int> fileBytes, String fileName) async {
    final path = '$gymId/$fileName';

    await _client.storage
        .from(AppConstants.gymLogosBucket)
        .uploadBinary(path, fileBytes as dynamic);

    return _client.storage.from(AppConstants.gymLogosBucket).getPublicUrl(path);
  }

  /// Upload a progress photo.
  Future<String> uploadProgressPhoto(
    String clientId,
    List<int> fileBytes,
    String fileName,
  ) async {
    final path = '$clientId/$fileName';

    await _client.storage
        .from(AppConstants.progressPhotosBucket)
        .uploadBinary(path, fileBytes as dynamic);

    return _client.storage
        .from(AppConstants.progressPhotosBucket)
        .getPublicUrl(path);
  }

  /// Delete a file from a bucket.
  Future<void> deleteFile(String bucket, String path) async {
    await _client.storage.from(bucket).remove([path]);
  }
}
