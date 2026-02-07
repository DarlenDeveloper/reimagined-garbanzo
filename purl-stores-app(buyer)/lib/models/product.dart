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
  ]) {
    final data = doc.data() ?? {};
    
    return Product(
      id: doc.id,
      storeId: storeId,
      storeName: storeName,
      storeLogo: storeLogo,
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

  /// Get discount percentage if compare price exists
  int? get discountPercentage {
    if (compareAtPrice == null || compareAtPrice! <= price) return null;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  /// Calculate markup percentage based on price and currency
  static double _getMarkupPercentage(double price, String currency) {
    // Convert thresholds based on currency
    // Base tiers are in UGX
    switch (currency.toUpperCase()) {
      case 'UGX': // Ugandan Shilling (base currency)
        if (price >= 500001) return 0.03;
        if (price >= 260001) return 0.04;
        if (price >= 125001) return 0.06;
        if (price >= 100001) return 0.09;
        if (price >= 75001) return 0.11;
        if (price >= 50001) return 0.14;
        if (price >= 25000) return 0.168;
        return 0.168;
        
      case 'KES': // Kenyan Shilling (1 KES ≈ 28.7 UGX)
        if (price >= 17422) return 0.03;  // 500,001 UGX
        if (price >= 9059) return 0.04;   // 260,001 UGX
        if (price >= 4355) return 0.06;   // 125,001 UGX
        if (price >= 3484) return 0.09;   // 100,001 UGX
        if (price >= 2613) return 0.11;   // 75,001 UGX
        if (price >= 1742) return 0.14;   // 50,001 UGX
        if (price >= 871) return 0.168;   // 25,000 UGX
        return 0.168;
        
      case 'TZS': // Tanzanian Shilling (1 TZS ≈ 1.48 UGX)
        if (price >= 337838) return 0.03; // 500,001 UGX
        if (price >= 175676) return 0.04; // 260,001 UGX
        if (price >= 84459) return 0.06;  // 125,001 UGX
        if (price >= 67568) return 0.09;  // 100,001 UGX
        if (price >= 50676) return 0.11;  // 75,001 UGX
        if (price >= 33784) return 0.14;  // 50,001 UGX
        if (price >= 16892) return 0.168; // 25,000 UGX
        return 0.168;
        
      case 'USD': // US Dollar (1 USD ≈ 3,700 UGX)
        if (price >= 135) return 0.03;    // 500,001 UGX
        if (price >= 70) return 0.04;     // 260,001 UGX
        if (price >= 34) return 0.06;     // 125,001 UGX
        if (price >= 27) return 0.09;     // 100,001 UGX
        if (price >= 20) return 0.11;     // 75,001 UGX
        if (price >= 14) return 0.14;     // 50,001 UGX
        if (price >= 7) return 0.168;     // 25,000 UGX
        return 0.168;
        
      case 'EUR': // Euro (1 EUR ≈ 4,022 UGX)
        if (price >= 124) return 0.03;    // 500,001 UGX
        if (price >= 65) return 0.04;     // 260,001 UGX
        if (price >= 31) return 0.06;     // 125,001 UGX
        if (price >= 25) return 0.09;     // 100,001 UGX
        if (price >= 19) return 0.11;     // 75,001 UGX
        if (price >= 12) return 0.14;     // 50,001 UGX
        if (price >= 6) return 0.168;     // 25,000 UGX
        return 0.168;
        
      case 'GBP': // British Pound (1 GBP ≈ 4,684 UGX)
        if (price >= 107) return 0.03;    // 500,001 UGX
        if (price >= 56) return 0.04;     // 260,001 UGX
        if (price >= 27) return 0.06;     // 125,001 UGX
        if (price >= 21) return 0.09;     // 100,001 UGX
        if (price >= 16) return 0.11;     // 75,001 UGX
        if (price >= 11) return 0.14;     // 50,001 UGX
        if (price >= 5) return 0.168;     // 25,000 UGX
        return 0.168;
        
      default:
        // For unknown currencies, use UGX tiers
        if (price >= 500001) return 0.03;
        if (price >= 260001) return 0.04;
        if (price >= 125001) return 0.06;
        if (price >= 100001) return 0.09;
        if (price >= 75001) return 0.11;
        if (price >= 50001) return 0.14;
        if (price >= 25000) return 0.168;
        return 0.168;
    }
  }

  /// Get final buyer price with markup
  double get finalPrice {
    final markup = _getMarkupPercentage(price, currency);
    return price + (price * markup);
  }

  /// Get final compare at price with markup (if exists)
  double? get finalCompareAtPrice {
    if (compareAtPrice == null) return null;
    final markup = _getMarkupPercentage(compareAtPrice!, currency);
    return compareAtPrice! + (compareAtPrice! * markup);
  }
}
