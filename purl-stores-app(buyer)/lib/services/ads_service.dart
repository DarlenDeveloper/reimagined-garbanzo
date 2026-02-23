import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ad.dart';

class AdsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get active ads stream
  Stream<List<Ad>> getActiveAdsStream({int limit = 10}) {
    return _firestore
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .where('viewsRemaining', isGreaterThan: 0)
        .orderBy('viewsRemaining', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      // Fetch store data for each ad
      final ads = <Ad>[];
      for (final doc in snapshot.docs) {
        final ad = Ad.fromFirestore(doc);
        
        // Fetch store data (name and logo)
        String storeName = ad.storeName;
        String? storeLogo = ad.storeLogo;
        
        try {
          final storeDoc = await _firestore.collection('stores').doc(ad.storeId).get();
          if (storeDoc.exists) {
            final storeData = storeDoc.data();
            // Use actual store name from stores collection (field is 'name', not 'storeName')
            storeName = storeData?['name'] as String? ?? ad.storeName;
            // Fetch logo if not in ad (field is 'logoUrl', not 'logo')
            if (storeLogo == null) {
              storeLogo = storeData?['logoUrl'] as String?;
            }
          }
        } catch (e) {
          print('❌ Error fetching store data for ${ad.storeId}: $e');
        }
        
        ads.add(Ad(
          id: ad.id,
          storeId: ad.storeId,
          storeName: storeName,
          storeLogo: storeLogo,
          images: ad.images,
          budget: ad.budget,
          totalViews: ad.totalViews,
          viewsRemaining: ad.viewsRemaining,
          status: ad.status,
          clicks: ad.clicks,
          storeVisits: ad.storeVisits,
          createdAt: ad.createdAt,
          activatedAt: ad.activatedAt,
        ));
      }
      return ads;
    });
  }

  /// Record an ad view
  Future<void> recordAdView(String adId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // Check if user already viewed this ad today
    final existingView = await _firestore
        .collection('adViews')
        .where('adId', isEqualTo: adId)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: dateStr)
        .limit(1)
        .get();

    if (existingView.docs.isEmpty) {
      // Record new view
      await _firestore.collection('adViews').add({
        'adId': adId,
        'userId': userId,
        'viewedAt': FieldValue.serverTimestamp(),
        'date': dateStr,
      });

      // Decrement viewsRemaining
      await _firestore.collection('ads').doc(adId).update({
        'viewsRemaining': FieldValue.increment(-1),
      });

      // Check if ad is completed
      final adDoc = await _firestore.collection('ads').doc(adId).get();
      if (adDoc.exists) {
        final viewsRemaining = adDoc.data()?['viewsRemaining'] ?? 0;
        if (viewsRemaining <= 0) {
          await _firestore.collection('ads').doc(adId).update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  /// Record an ad click
  Future<void> recordAdClick(String adId) async {
    await _firestore.collection('ads').doc(adId).update({
      'clicks': FieldValue.increment(1),
    });
  }

  /// Record a store visit from ad
  Future<void> recordStoreVisit(String adId) async {
    await _firestore.collection('ads').doc(adId).update({
      'storeVisits': FieldValue.increment(1),
    });
  }
}
