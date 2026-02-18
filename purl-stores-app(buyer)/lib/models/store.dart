import 'package:cloud_firestore/cloud_firestore.dart';

/// Store model for buyer app
/// Reads from /stores/{storeId}
class Store {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? location;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final int followerCount;
  final int productCount;
  final DateTime? createdAt;

  Store({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.location,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.followerCount = 0,
    this.productCount = 0,
    this.createdAt,
  });

  factory Store.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    // Handle location field - can be String or GeoPoint
    String? locationStr;
    final locationData = data['location'];
    if (locationData is String) {
      locationStr = locationData;
    } else if (locationData is GeoPoint) {
      locationStr = '${locationData.latitude}, ${locationData.longitude}';
    }
    
    return Store(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown Store',
      description: data['description'] as String?,
      logoUrl: data['logoUrl'] as String?,
      bannerUrl: data['bannerUrl'] as String?,
      location: locationStr,
      isVerified: data['isVerified'] as bool? ?? false,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      followerCount: data['followerCount'] as int? ?? 0,
      productCount: data['productCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Get first letter for avatar
  String get avatarLetter => name.isNotEmpty ? name[0].toUpperCase() : 'S';
}
