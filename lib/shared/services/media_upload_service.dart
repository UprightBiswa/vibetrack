import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MediaUploadService {
  Future<String> uploadPostMedia({
    required String userId,
    required String sessionId,
    required Uint8List bytes,
    String fileExtension = 'png',
    String contentType = 'image/png',
  });
}

class SupabaseMediaUploadService implements MediaUploadService {
  SupabaseMediaUploadService(this._client);
  final SupabaseClient _client;

  @override
  Future<String> uploadPostMedia({
    required String userId,
    required String sessionId,
    required Uint8List bytes,
    String fileExtension = 'png',
    String contentType = 'image/png',
  }) async {
    final path =
        '$userId/$sessionId-${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    try {
      await _client.storage.from('posts').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType),
      );
    } on StorageException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('403') ||
          message.contains('not authorized') ||
          message.contains('permission') ||
          message.contains('row-level security') ||
          message.contains('violates row-level security policy')) {
        throw Exception(
          'Post upload is blocked by Supabase Storage policy for the `posts` bucket. Create the bucket and add authenticated upload + public read policies before publishing media.',
        );
      }
      throw Exception(error.message);
    }
    return _client.storage.from('posts').getPublicUrl(path);
  }
}

class LocalMediaUploadService implements MediaUploadService {
  @override
  Future<String> uploadPostMedia({
    required String userId,
    required String sessionId,
    required Uint8List bytes,
    String fileExtension = 'png',
    String contentType = 'image/png',
  }) async {
    return 'local://$userId/$sessionId.$fileExtension';
  }
}
