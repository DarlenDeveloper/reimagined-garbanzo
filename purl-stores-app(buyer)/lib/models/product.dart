import 'package:cloud_firestore/cloud_firestore.dart';

/// Product image model
class ProductImage {
  final String url;
  final String? thumbnailUrl;
  final int sortOrder;

  ProductImage({
    required this.url,
    this.thumbnailUrl,
    this.sortOrder = 0,
  });

  factory ProductImage.fromMap(Map<String, dynamic> map) {
    return ProductImage(
      url: map['url'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String?,
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }
}

/// Product model for buyer app
/// Reads from /stores/{storeId}/products/{productId}
class Product {
  final String id;
  final String storeId;
  final String storeName;
  final String? storeLogo;
  final String? storeVerificationStatus;
  
  // Basic info
  final String name;
  final String description;
  final String categoryId;
  final String? subcategoryId;
  final String? productTypeId;
  final String? condition;
  
  // Pricing
  final double price;
  final double? compareAtPrice;
  final String currency;
  
  // Media
  final List<ProductImage> images;
  final Map<String, dynamic> specs;
  
  // Inventory
  final int stock;
  final bool trackInventory;
  
  // Status
  final bool isActive;
  final bool isFeatured;
  
  // Stats
  final double rating;
  final int reviewCount;
  final int totalSold;
  
  // Timestamps
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.storeId,
    required this.storeName,
    this.storeLogo,
    this.storeVerificationStatus,
    required this.name,
    this.description = '',
    required this.categoryId,
    this.subcategoryId,
    this.productTypeId,
    this.condition,
    required this.price,
    this.compareAtPrice,
    this.currency = 'KES',
    this.images = const [],
    this.specs = const {},
    this.stock = 0,
    this.trackInventory = true,
    this.isActive = true,
    this.isFeatured = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.totalSold = 0,
    this.createdAt,
  });

  /// Create from Firestore document
  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String storeId,
    String storeName, [
    String? storeLogo,
    String? storeVerificationStatus,
  ]) {
    final data = doc.data() ?? {};
    
    return Product(
      id: doc.id,
      storeId: storeId,
      storeName: storeName,
      storeLogo: storeLogo,
      storeVerificationStatus: storeVerificationStatus,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      subcategoryId: data['subcategoryId'] as String?,
      productTypeId: data['productTypeId'] as String?,
      condition: data['condition'] as String?,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      compareAtPrice: (data['compareAtPrice'] as num?)?.toDouble(),
      currency: data['currency'] as String? ?? 'KES',
      images: (data['images'] as List<dynamic>?)
          ?.map((e) => ProductImage.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      specs: Map<String, dynamic>.from(data['specs'] as Map? ?? {}),
      stock: data['stock'] as int? ?? 0,
      trackInventory: data['trackInventory'] as bool? ?? true,
      isActive: data['isActive'] as bool? ?? true,
      isFeatured: data['isFeatured'] as bool? ?? false,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      totalSold: data['totalSold'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Get primary image URL
  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final sorted = List<ProductImage>.from(images)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.first.url;
  }

  /// Check if product is in stock
  bool get isInStock => !trackInventory || stock > 0;

  /// Check if store is verified
  bool get isStoreVerified => storeVerificationStatus == 'verified';

  /// Get discount percentage if compare price exists
  int? get discountPercentage {
    if (compareAtPrice == null || compareAtPrice! <= price) return null;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }
}
