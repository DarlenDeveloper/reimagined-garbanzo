import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../models/product.dart';

/// ImageService handles all image upload/download operations with Firebase Storage.
/// 
/// STORAGE STRUCTURE:
/// /stores/{storeId}/
/// ├── logo.{ext}
/// ├── banner.{ext}
/// └── products/{productId}/
///     ├── image_0.{ext}
///     ├── image_1.{ext}
///     └── ...
/// 
/// USAGE:
/// ```dart
/// final imageService = ImageService();
/// 
/// // Pick and upload product images
/// final images = await imageService.pickProductImages();
/// final uploadedImages = await imageService.uploadProductImages(
///   storeId: 'store123',
///   productId: 'product123',
///   files: images,
/// );
/// 
/// // Upload store logo
/// final logoUrl = await imageService.uploadStoreLogo('store123', logoFile);
/// ```
class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  /// Maximum file size in bytes (5MB)
  static const int maxFileSize = 5 * 1024 * 1024;

  /// Allowed image extensions
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  /// Maximum number of product images
  static const int maxProductImages = 10;

  // ============ IMAGE PICKING ============

  /// Pick a single image from gallery or camera.
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1200,
    int maxHeight = 1200,
    int imageQuality = 85,
  }) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Pick multiple images from gallery.
  Future<List<XFile>> pickMultipleImages({
    int maxWidth = 1200,
    int maxHeight = 1200,
    int imageQuality = 85,
    int? limit,
  }) async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
        limit: limit,
      );
      return images;
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  /// Pick product images (up to maxProductImages).
  Future<List<XFile>> pickProductImages() async {
    return pickMultipleImages(limit: maxProductImages);
  }

  // ============ VALIDATION ============

  /// Validate image file before upload.
  Future<void> _validateImage(File file) async {
    // Check file exists
    if (!await file.exists()) {
      throw Exception('Image file does not exist');
    }

    // Check file size
    final size = await file.length();
    if (size > maxFileSize) {
      throw Exception('Image file too large. Maximum size is ${maxFileSize ~/ (1024 * 1024)}MB');
    }

    // Check extension
    final ext = path.extension(file.path).toLowerCase().replaceAll('.', '');
    if (!allowedExtensions.contains(ext)) {
      throw Exception('Invalid image format. Allowed: ${allowedExtensions.join(', ')}');
    }
  }

  /// Verify current user has access to the store.
  Future<bool> _verifyStoreAccess(String storeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final store = await _firestore.collection('stores').doc(storeId).get();
    if (!store.exists) return false;

    final authorizedUsers = List<String>.from(store.data()?['authorizedUsers'] ?? []);
    return authorizedUsers.contains(uid);
  }

  // ============ PRODUCT IMAGES ============

  /// Upload a single product image.
  /// Returns ProductImage with download URL.
  Future<ProductImage> uploadProductImage({
    required String storeId,
    required String productId,
    required File file,
    required int sortOrder,
    void Function(double)? onProgress,
  }) async {
    // Verify access
    if (!await _verifyStoreAccess(storeId)) {
      throw Exception('Access denied: User does not have access to this store');
    }

    // Validate image
    await _validateImage(file);

    // Generate unique filename
    final ext = path.extension(file.path).toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'image_${sortOrder}_$timestamp$ext';

    // Storage path
    final storagePath = 'stores/$storeId/products/$productId/$filename';
    final ref = _storage.ref().child(storagePath);

    // Upload with progress tracking
    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/${ext.replaceAll('.', '')}',
        customMetadata: {
          'uploadedBy': _auth.currentUser?.uid ?? 'unknown',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      ),
    );

    // Track progress
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    // Wait for upload to complete
    await uploadTask;

    // Get download URL
    final downloadUrl = await ref.getDownloadURL();

    return ProductImage(
      url: downloadUrl,
      sortOrder: sortOrder,
    );
  }

  /// Upload multiple product images.
  /// Returns list of ProductImage with download URLs.
  Future<List<ProductImage>> uploadProductImages({
    required String storeId,
    required String productId,
    required List<XFile> files,
    void Function(int current, int total, double progress)? onProgress,
  }) async {
    if (files.isEmpty) return [];

    if (files.length > maxProductImages) {
      throw Exception('Maximum $maxProductImages images allowed');
    }

    final List<ProductImage> uploadedImages = [];

    for (int i = 0; i < files.length; i++) {
      final file = File(files[i].path);
      
      final image = await uploadProductImage(
        storeId: storeId,
        productId: productId,
        file: file,
        sortOrder: i,
        onProgress: (progress) {
          onProgress?.call(i + 1, files.length, progress);
        },
      );

      uploadedImages.add(image);
    }

    return uploadedImages;
  }

  /// Delete a product image from storage.
  Future<void> deleteProductImage({
    required String storeId,
    required String productId,
    required String imageUrl,
  }) async {
    if (!await _verifyStoreAccess(storeId)) {
      throw Exception('Access denied: User does not have access to this store');
    }

    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Image might already be deleted or URL invalid
      // Log but don't throw
      print('Warning: Could not delete image: $e');
    }
  }

  /// Delete all images for a product.
  Future<void> deleteAllProductImages({
    required String storeId,
    required String productId,
  }) async {
    if (!await _verifyStoreAccess(storeId)) {
      throw Exception('Access denied: User does not have access to this store');
    }

    try {
      final folderRef = _storage.ref().child('stores/$storeId/products/$productId');
      final listResult = await folderRef.listAll();

      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      print('Warning: Could not delete product images folder: $e');
    }
  }

  // ============ STORE IMAGES ============

  /// Upload store logo.
  /// Returns download URL.
  Future<String> uploadStoreLogo(String storeId, File file) async {
    if (!await _verifyStoreAccess(storeId)) {
      throw Exception('Access denied: User does not have access to this store');
    }

    await _validateImage(file);

    final ext = path.extension(file.path).toLowerCase();
    final storagePath = 'stores/$storeId/logo$ext';
    final ref = _storage.ref().child(storagePath);

    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/${ext.replaceAll('.', '')}'),
    );

    return await ref.getDownloadURL();
  }

  /// Upload store banner.
  /// Returns download URL.
  Future<String> uploadStoreBanner(String storeId, File file) async {
    if (!await _verifyStoreAccess(storeId)) {
      throw Exception('Access denied: User does not have access to this store');
    }

    await _validateImage(file);

    final ext = path.extension(file.path).toLowerCase();
    final storagePath = 'stores/$storeId/banner$ext';
    final ref = _storage.ref().child(storagePath);

    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/${ext.replaceAll('.', '')}'),
    );

    return await ref.getDownloadURL();
  }

  // ============ UTILITIES ============

  /// Get file size in human-readable format.
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if URL is a Firebase Storage URL.
  bool isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com') ||
           url.contains('storage.googleapis.com');
  }
}
