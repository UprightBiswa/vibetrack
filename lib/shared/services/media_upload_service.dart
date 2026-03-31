import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibetreck/core/providers/repositories.dart';

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return LocalMediaUploadService();
  }
  return SupabaseMediaUploadService(client);
});

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
          message.contains('permission')) {
        throw Exception(
          'Post upload is blocked by Supabase Storage policy. Create a public `posts` bucket and allow authenticated uploads.',
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
