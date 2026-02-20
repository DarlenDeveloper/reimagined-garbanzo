import 'package:cloud_firestore/cloud_firestore.dart';

class Ad {
  final String id;
  final String storeId;
  final String storeName;
  final String? storeLogo;
  final List<String> images;
  final double budget;
  final int totalViews;
  final int viewsRemaining;
  final String status;
  final int clicks;
  final int storeVisits;
  final DateTime? createdAt;
  final DateTime? activatedAt;

  Ad({
    required this.id,
    required this.storeId,
    required this.storeName,
    this.storeLogo,
    required this.images,
    required this.budget,
    required this.totalViews,
    required this.viewsRemaining,
    required this.status,
    required this.clicks,
    required this.storeVisits,
    this.createdAt,
    this.activatedAt,
  });

  factory Ad.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ad(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      storeLogo: data['storeLogo'],
      images: List<String>.from(data['images'] ?? []),
      budget: (data['budget'] ?? 0).toDouble(),
      totalViews: data['totalViews'] ?? 0,
      viewsRemaining: data['viewsRemaining'] ?? 0,
      status: data['status'] ?? 'draft',
      clicks: data['clicks'] ?? 0,
      storeVisits: data['storeVisits'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      activatedAt: data['activatedAt'] != null 
          ? (data['activatedAt'] as Timestamp).toDate() 
          : null,
    );
  }
}
