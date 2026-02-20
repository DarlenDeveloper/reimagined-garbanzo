import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AdsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Create a new ad
  Future<String> createAd({
    required String title,
    required List<File> images,
    required double budget,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Get the store ID for the current user
      final storeQuery = await _firestore
          .collection('stores')
          .where('authorizedUsers', arrayContains: _userId)
          .limit(1)
          .get();

      if (storeQuery.docs.isEmpty) {
        throw Exception('No store found for current user');
      }

      final storeId = storeQuery.docs.first.id;
      final storeData = storeQuery.docs.first.data();
      final storeName = storeData['storeName'] ?? 'Unknown Store';
      final storeLogo = storeData['logo'] as String?;

      // Upload images to Firebase Storage
      final List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final fileName = 'ads/$storeId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child(fileName);
        await ref.putFile(images[i]);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Calculate total views
      final totalViews = (budget * 1024).toInt();

      // Create ad document
      final adData = {
        'storeId': storeId, // Now using actual storeId instead of userId
        'storeName': storeName,
        'storeLogo': storeLogo,
        'title': title,
        'images': imageUrls,
        'budget': budget,
        'totalViews': totalViews,
        'viewsRemaining': totalViews,
        'clicks': 0,
        'storeVisits': 0,
        'status': 'pending_payment', // Will change to 'active' after payment
        'createdAt': FieldValue.serverTimestamp(),
        'activatedAt': null,
        'completedAt': null,
      };

      final docRef = await _firestore.collection('ads').add(adData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create ad: $e');
    }
  }

  // Get all ads for current store
  Stream<List<Map<String, dynamic>>> getMyAds() async* {
    if (_userId == null) {
      yield [];
      return;
    }

    // Get the store ID for the current user
    final storeQuery = await _firestore
        .collection('stores')
        .where('authorizedUsers', arrayContains: _userId)
        .limit(1)
        .get();

    if (storeQuery.docs.isEmpty) {
      yield [];
      return;
    }

    final storeId = storeQuery.docs.first.id;

    yield* _firestore
        .collection('ads')
        .where('storeId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get active ads only
  Stream<List<Map<String, dynamic>>> getActiveAds() async* {
    if (_userId == null) {
      yield [];
      return;
    }

    // Get the store ID for the current user
    final storeQuery = await _firestore
        .collection('stores')
        .where('authorizedUsers', arrayContains: _userId)
        .limit(1)
        .get();

    if (storeQuery.docs.isEmpty) {
      yield [];
      return;
    }

    final storeId = storeQuery.docs.first.id;

    yield* _firestore
        .collection('ads')
        .where('storeId', isEqualTo: storeId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Update ad status (for payment completion)
  Future<void> updateAdStatus(String adId, String status) async {
    await _firestore.collection('ads').doc(adId).update({
      'status': status,
      if (status == 'active') 'activatedAt': FieldValue.serverTimestamp(),
      if (status == 'completed') 'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get analytics summary
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    if (_userId == null) return {};

    try {
      // Get the store ID for the current user
      final storeQuery = await _firestore
          .collection('stores')
          .where('authorizedUsers', arrayContains: _userId)
          .limit(1)
          .get();

      if (storeQuery.docs.isEmpty) {
        return {
          'totalViews': 0,
          'totalClicks': 0,
          'totalSpent': 0.0,
          'ctr': 0.0,
        };
      }

      final storeId = storeQuery.docs.first.id;

      final snapshot = await _firestore
          .collection('ads')
          .where('storeId', isEqualTo: storeId)
          .get();

      int totalViews = 0;
      int totalClicks = 0;
      double totalSpent = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final delivered = (data['totalViews'] ?? 0) - (data['viewsRemaining'] ?? 0);
        totalViews += delivered as int;
        totalClicks += (data['clicks'] ?? 0) as int;
        totalSpent += (data['budget'] ?? 0.0) as double;
      }

      final ctr = totalViews > 0 ? (totalClicks / totalViews * 100) : 0.0;

      return {
        'totalViews': totalViews,
        'totalClicks': totalClicks,
        'totalSpent': totalSpent,
        'ctr': ctr,
      };
    } catch (e) {
      return {
        'totalViews': 0,
        'totalClicks': 0,
        'totalSpent': 0.0,
        'ctr': 0.0,
      };
    }
  }

  // Delete an ad
  Future<void> deleteAd(String adId) async {
    await _firestore.collection('ads').doc(adId).delete();
  }
}
