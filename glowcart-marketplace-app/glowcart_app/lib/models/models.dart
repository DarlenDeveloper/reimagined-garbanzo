class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String vendorId;
  final String vendorName;
  final double rating;
  final int reviewCount;
  final bool isFavorite;
  final Map<String, String> specs;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.vendorId,
    required this.vendorName,
    this.rating = 0,
    this.reviewCount = 0,
    this.isFavorite = false,
    this.specs = const {},
  });

  Product copyWith({bool? isFavorite}) {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      category: category,
      vendorId: vendorId,
      vendorName: vendorName,
      rating: rating,
      reviewCount: reviewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      specs: specs,
    );
  }
}

class Vendor {
  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final String location;
  final double rating;
  final int reviewCount;
  final int followerCount;
  final int productCount;
  final bool isFollowing;
  final bool isVerified;

  Vendor({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.location,
    this.rating = 0,
    this.reviewCount = 0,
    this.followerCount = 0,
    this.productCount = 0,
    this.isFollowing = false,
    this.isVerified = false,
  });
}

class Category {
  final String id;
  final String name;
  final String icon;
  final int productCount;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.productCount = 0,
  });
}

class CartItem {
  final String id;
  final Product product;
  int quantity;

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
  });
}

class SocialPost {
  final String id;
  final String vendorId;
  final String vendorName;
  final String vendorLogo;
  final String content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime expiresAt;
  // Discount/Promo fields
  final bool hasDiscount;
  final int? discountPercent;
  final String? promoCode;
  final String? postType; // 'promo', 'announcement', 'restock', 'new_arrival'

  SocialPost({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.vendorLogo,
    required this.content,
    this.imageUrl,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.expiresAt,
    this.hasDiscount = false,
    this.discountPercent,
    this.promoCode,
    this.postType,
  });
}

class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final List<Address> addresses;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.addresses = const [],
  });
}

class Address {
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });
}
