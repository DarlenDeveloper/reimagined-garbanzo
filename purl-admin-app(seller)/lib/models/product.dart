import 'package:cloud_firestore/cloud_firestore.dart';

/// Product image with URL and optional thumbnail
class ProductImage {
  final String url;
  final String? thumbnailUrl;
  final int sortOrder;

  const ProductImage({
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

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'sortOrder': sortOrder,
    };
  }

  ProductImage copyWith({
    String? url,
    String? thumbnailUrl,
    int? sortOrder,
  }) {
    return ProductImage(
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Product variant (e.g., size/color combinations with their own stock)
class ProductVariant {
  final String id;
  final String name;       // e.g., "Size", "Color"
  final String value;      // e.g., "Large", "Red"
  final double? price;     // Override price for this variant
  final String? sku;
  final int stock;

  const ProductVariant({
    required this.id,
    required this.name,
    required this.value,
    this.price,
    this.sku,
    this.stock = 0,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      value: map['value'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble(),
      sku: map['sku'] as String?,
      stock: map['stock'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'price': price,
      'sku': sku,
      'stock': stock,
    };
  }

  ProductVariant copyWith({
    String? id,
    String? name,
    String? value,
    double? price,
    String? sku,
    int? stock,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      price: price ?? this.price,
      sku: sku ?? this.sku,
      stock: stock ?? this.stock,
    );
  }
}


/// Main Product model
/// 
/// Firestore path: /stores/{storeId}/products/{productId}
/// 
/// Products are stored under their parent store for:
/// - Efficient queries (get all products for a store)
/// - Security rules (store owners can only access their products)
/// - Scalability (products are partitioned by store)
class Product {
  final String id;
  final String storeId;
  final String name;
  final String? slug;
  final String description;
  
  // Category hierarchy
  final String categoryId;        // Top-level category (e.g., 'electronics')
  final String? subcategoryId;    // Subcategory (e.g., 'cell_phones')
  final String? productTypeId;    // Product type (e.g., 'smartphones')
  final String? categoryPath;     // Full path: 'electronics/cell_phones/smartphones'
  final String? condition;        // 'New', 'Used', 'Refurbished', 'Collectible'
  
  // Pricing
  final double price;
  final double? compareAtPrice;   // Original price for showing discounts
  final String currency;
  
  // Media
  final List<ProductImage> images;
  
  // Variants (optional - for products with size/color options)
  final List<ProductVariant> variants;
  
  // Category-specific attributes (dynamic based on product type)
  // e.g., {'brand': 'Apple', 'storage': '256GB', 'color': ['Black', 'White']}
  final Map<String, dynamic> specs;
  
  // Tags for search
  final List<String> tags;
  
  // Inventory
  final int stock;                // For non-variant products
  final int lowStockThreshold;
  final bool trackInventory;
  
  // Status flags
  final bool isActive;            // Visible to buyers
  final bool isPublished;         // Listed on marketplace
  final bool isFeatured;          // Highlighted in store
  
  // Stats (updated by system)
  final double rating;
  final int reviewCount;
  final int totalSold;
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    this.slug,
    this.description = '',
    required this.categoryId,
    this.subcategoryId,
    this.productTypeId,
    this.categoryPath,
    this.condition,
    required this.price,
    this.compareAtPrice,
    this.currency = 'KES',
    this.images = const [],
    this.variants = const [],
    this.specs = const {},
    this.tags = const [],
    this.stock = 0,
    this.lowStockThreshold = 5,
    this.trackInventory = true,
    this.isActive = true,
    this.isPublished = false,
    this.isFeatured = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.totalSold = 0,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  /// Create Product from Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc, String storeId) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Product.fromMap(data, doc.id, storeId);
  }

  /// Create Product from Map (used by fromFirestore)
  factory Product.fromMap(Map<String, dynamic> map, String id, String storeId) {
    return Product(
      id: id,
      storeId: storeId,
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String?,
      description: map['description'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? 'other',
      subcategoryId: map['subcategoryId'] as String?,
      productTypeId: map['productTypeId'] as String?,
      categoryPath: map['categoryPath'] as String?,
      condition: map['condition'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      compareAtPrice: (map['compareAtPrice'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'KES',
      images: (map['images'] as List<dynamic>?)
          ?.map((e) => ProductImage.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      variants: (map['variants'] as List<dynamic>?)
          ?.map((e) => ProductVariant.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      specs: Map<String, dynamic>.from(map['specs'] as Map? ?? {}),
      tags: List<String>.from(map['tags'] as List? ?? []),
      stock: map['stock'] as int? ?? 0,
      lowStockThreshold: map['lowStockThreshold'] as int? ?? 5,
      trackInventory: map['trackInventory'] as bool? ?? true,
      isActive: map['isActive'] as bool? ?? true,
      isPublished: map['isPublished'] as bool? ?? false,
      isFeatured: map['isFeatured'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] as int? ?? 0,
      totalSold: map['totalSold'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      publishedAt: (map['publishedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Map for Firestore (excludes id and storeId - they're in the path)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug ?? _generateSlug(name),
      'description': description,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'productTypeId': productTypeId,
      'categoryPath': categoryPath,
      'condition': condition,
      'price': price,
      'compareAtPrice': compareAtPrice,
      'currency': currency,
      'images': images.map((e) => e.toMap()).toList(),
      'variants': variants.map((e) => e.toMap()).toList(),
      'specs': specs,
      'tags': tags,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'trackInventory': trackInventory,
      'isActive': isActive,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'rating': rating,
      'reviewCount': reviewCount,
      'totalSold': totalSold,
      // Timestamps handled separately in service
    };
  }

  /// Generate URL-friendly slug from name
  static String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  /// Get computed stock status
  String get stockStatus {
    if (!trackInventory) return 'Not Tracked';
    if (stock <= 0) return 'Out of Stock';
    if (stock <= lowStockThreshold) return 'Low Stock';
    return 'In Stock';
  }

  /// Check if product has variants
  bool get hasVariants => variants.isNotEmpty;

  /// Get total stock across all variants (or base stock if no variants)
  int get totalStock {
    if (!hasVariants) return stock;
    return variants.fold(0, (total, v) => total + v.stock);
  }

  /// Get primary image URL
  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final sorted = List<ProductImage>.from(images)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.first.url;
  }

  /// Get discount percentage if compareAtPrice is set
  int? get discountPercentage {
    if (compareAtPrice == null || compareAtPrice! <= price) return null;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  /// Create a copy with updated fields
  Product copyWith({
    String? id,
    String? storeId,
    String? name,
    String? slug,
    String? description,
    String? categoryId,
    String? subcategoryId,
    String? productTypeId,
    String? categoryPath,
    String? condition,
    double? price,
    double? compareAtPrice,
    String? currency,
    List<ProductImage>? images,
    List<ProductVariant>? variants,
    Map<String, dynamic>? specs,
    List<String>? tags,
    int? stock,
    int? lowStockThreshold,
    bool? trackInventory,
    bool? isActive,
    bool? isPublished,
    bool? isFeatured,
    double? rating,
    int? reviewCount,
    int? totalSold,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return Product(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      productTypeId: productTypeId ?? this.productTypeId,
      categoryPath: categoryPath ?? this.categoryPath,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      compareAtPrice: compareAtPrice ?? this.compareAtPrice,
      currency: currency ?? this.currency,
      images: images ?? this.images,
      variants: variants ?? this.variants,
      specs: specs ?? this.specs,
      tags: tags ?? this.tags,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      trackInventory: trackInventory ?? this.trackInventory,
      isActive: isActive ?? this.isActive,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      totalSold: totalSold ?? this.totalSold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, stock: $stock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id && other.storeId == storeId;
  }

  @override
  int get hashCode => id.hashCode ^ storeId.hashCode;
}
