import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// MediaService handles image and video compression, thumbnail generation, and upload
class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image with thumbnail
  /// Returns map with thumbnailUrl and fullUrl
  Future<Map<String, dynamic>> uploadImage({
    required File imageFile,
    required String storeId,
    required String postId,
  }) async {
    try {
      // Generate thumbnail (compressed version)
      final thumbnailFile = await _compressImage(imageFile, quality: 50, maxWidth: 400);
      
      // Upload thumbnail
      final thumbnailPath = 'stores/$storeId/posts/$postId/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final thumbnailRef = _storage.ref().child(thumbnailPath);
      await thumbnailRef.putFile(thumbnailFile);
      final thumbnailUrl = await thumbnailRef.getDownloadURL();

      // Upload full quality (compressed but higher quality)
      final fullFile = await _compressImage(imageFile, quality: 85, maxWidth: 1920);
      final fullPath = 'stores/$storeId/posts/$postId/full_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fullRef = _storage.ref().child(fullPath);
      await fullRef.putFile(fullFile);
      final fullUrl = await fullRef.getDownloadURL();

      // Calculate aspect ratio
      final bytes = await imageFile.readAsBytes();
      final image = await _decodeImage(bytes);
      final aspectRatio = image.width / image.height;

      return {
        'type': 'image',
        'thumbnailUrl': thumbnailUrl,
        'fullUrl': fullUrl,
        'aspectRatio': aspectRatio,
      };
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload video with thumbnail
  /// Returns map with thumbnailUrl, fullUrl, and duration
  Future<Map<String, dynamic>> uploadVideo({
    required File videoFile,
    required String storeId,
    required String postId,
  }) async {
    try {
      // Generate video thumbnail
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 50,
      );

      if (thumbnailPath == null) {
        throw Exception('Failed to generate video thumbnail');
      }

      final thumbnailFile = File(thumbnailPath);

      // Upload thumbnail
      final thumbnailStoragePath = 'stores/$storeId/posts/$postId/video_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final thumbnailRef = _storage.ref().child(thumbnailStoragePath);
      await thumbnailRef.putFile(thumbnailFile);
      final thumbnailUrl = await thumbnailRef.getDownloadURL();

      // Compress video
      final compressedVideo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.LowQuality, // Changed to Low for faster upload
        deleteOrigin: false,
      );

      if (compressedVideo == null) {
        throw Exception('Failed to compress video');
      }

      // Upload compressed video
      final videoPath = 'stores/$storeId/posts/$postId/video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final videoRef = _storage.ref().child(videoPath);
      await videoRef.putFile(File(compressedVideo.path!));
      final videoUrl = await videoRef.getDownloadURL();

      // Get video duration and aspect ratio
      final duration = compressedVideo.duration ?? 0;
      final aspectRatio = (compressedVideo.width ?? 16) / (compressedVideo.height ?? 9);

      return {
        'type': 'video',
        'thumbnailUrl': thumbnailUrl,
        'fullUrl': videoUrl,
        'duration': duration,
        'aspectRatio': aspectRatio,
      };
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  /// Compress image
  Future<File> _compressImage(File file, {required int quality, required int maxWidth}) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg');

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: maxWidth > 1920 ? 1920 : maxWidth, // Cap at 1920px for faster upload
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('Image compression failed');
    }

    return File(result.path);
  }

  /// Decode image to get dimensions
  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }
}
