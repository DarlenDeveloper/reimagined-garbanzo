import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Cache for verification status
  static final Map<String, _CachedStatus> _statusCache = {};
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Get verification status for current store (with caching)
  Future<VerificationStatus> getVerificationStatus(String storeId) async {
    try {
      // Check cache first
      final cached = _statusCache[storeId];
      if (cached != null && DateTime.now().difference(cached.timestamp) < _cacheDuration) {
        print('✅ Using cached verification status: ${cached.status}');
        return cached.status;
      }

      print('🔍 Checking verification status for store: $storeId');
      final doc = await _firestore.collection('stores').doc(storeId).get();
      
      if (!doc.exists) {
        print('❌ Store document does not exist');
        return VerificationStatus.none;
      }

      final data = doc.data()!;
      final status = data['verificationStatus'] ?? 'none';
      print('📊 Raw status from Firestore: $status');
      
      final expiresAt = data['verificationExpiresAt'] as Timestamp?;

      // Check if expired
      if (status == 'verified' && expiresAt != null) {
        if (expiresAt.toDate().isBefore(DateTime.now())) {
          // Mark as expired
          await _firestore.collection('stores').doc(storeId).update({
            'verificationStatus': 'expired',
            'isVerified': false,
          });
          print('⏰ Status expired, marked as expired');
          final result = VerificationStatus.expired;
          _statusCache[storeId] = _CachedStatus(result, DateTime.now());
          return result;
        }
      }

      final result = VerificationStatus.fromString(status);
      print('✅ Returning status: $result');
      
      // Cache the result
      _statusCache[storeId] = _CachedStatus(result, DateTime.now());
      
      return result;
    } catch (e) {
      print('❌ Error getting verification status: $e');
      return VerificationStatus.none;
    }
  }

  /// Clear cache for a specific store (call after status changes)
  static void clearCache(String storeId) {
    _statusCache.remove(storeId);
  }

  /// Clear all cache
  static void clearAllCache() {
    _statusCache.clear();
  }

  /// Submit verification request
  Future<String> submitVerification({
    required String storeId,
    required String ownerName,
    required File idDocumentFront,
    required File idDocumentBack,
    required File faceScan,
    required String location,
  }) async {
    try {
      // Upload ID documents and face scan
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final frontRef = _storage.ref().child('verification_documents/$storeId/front_$timestamp.jpg');
      final backRef = _storage.ref().child('verification_documents/$storeId/back_$timestamp.jpg');
      final faceRef = _storage.ref().child('verification_documents/$storeId/face_$timestamp.jpg');
      
      await Future.wait([
        frontRef.putFile(idDocumentFront),
        backRef.putFile(idDocumentBack),
        faceRef.putFile(faceScan),
      ]);
      
      final idDocumentFrontUrl = await frontRef.getDownloadURL();
      final idDocumentBackUrl = await backRef.getDownloadURL();
      final faceScanUrl = await faceRef.getDownloadURL();

      // Update store with verification data
      await _firestore.collection('stores').doc(storeId).update({
        'verificationStatus': 'pending',
        'verificationData': {
          'ownerName': ownerName,
          'idDocumentFront': idDocumentFrontUrl,
          'idDocumentBack': idDocumentBackUrl,
          'faceScan': faceScanUrl,
          'location': location,
          'submittedAt': FieldValue.serverTimestamp(),
        },
      });

      // Clear cache after status change
      VerificationService.clearCache(storeId);

      return 'success';
    } catch (e) {
      print('Error submitting verification: $e');
      throw Exception('Failed to submit verification');
    }
  }

  /// Record verification payment
  Future<void> recordVerificationPayment({
    required String storeId,
    required String transactionId,
    required double amount,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));

      await _firestore.collection('stores').doc(storeId).update({
        'verificationPayments': FieldValue.arrayUnion([
          {
            'amount': amount,
            'transactionId': transactionId,
            'paidAt': Timestamp.fromDate(now),
            'expiresAt': Timestamp.fromDate(expiresAt),
          }
        ]),
        'lastVerificationPayment': {
          'amount': amount,
          'transactionId': transactionId,
          'paidAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(expiresAt),
        },
      });
    } catch (e) {
      print('Error recording payment: $e');
      throw Exception('Failed to record payment');
    }
  }

  /// Approve verification (admin only)
  Future<void> approveVerification(String storeId) async {
    try {
      final expiresAt = DateTime.now().add(const Duration(days: 30));

      await _firestore.collection('stores').doc(storeId).update({
        'verificationStatus': 'verified',
        'isVerified': true,
        'verificationExpiresAt': Timestamp.fromDate(expiresAt),
        'verificationData.approvedAt': FieldValue.serverTimestamp(),
      });

      // Clear cache after status change
      VerificationService.clearCache(storeId);
    } catch (e) {
      print('Error approving verification: $e');
      throw Exception('Failed to approve verification');
    }
  }

  /// Renew verification
  Future<void> renewVerification({
    required String storeId,
    required String transactionId,
    required double amount,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));

      await _firestore.collection('stores').doc(storeId).update({
        'verificationStatus': 'verified',
        'isVerified': true,
        'verificationExpiresAt': Timestamp.fromDate(expiresAt),
        'verificationPayments': FieldValue.arrayUnion([
          {
            'amount': amount,
            'transactionId': transactionId,
            'paidAt': Timestamp.fromDate(now),
            'expiresAt': Timestamp.fromDate(expiresAt),
            'isRenewal': true,
          }
        ]),
        'lastVerificationPayment': {
          'amount': amount,
          'transactionId': transactionId,
          'paidAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(expiresAt),
          'isRenewal': true,
        },
      });

      // Clear cache after status change
      VerificationService.clearCache(storeId);
    } catch (e) {
      print('Error renewing verification: $e');
      throw Exception('Failed to renew verification');
    }
  }

  /// Check if verification is expiring soon (within 7 days)
  Future<bool> isExpiringSoon(String storeId) async {
    try {
      final doc = await _firestore.collection('stores').doc(storeId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final expiresAt = data['verificationExpiresAt'] as Timestamp?;
      
      if (expiresAt == null) return false;

      final daysUntilExpiry = expiresAt.toDate().difference(DateTime.now()).inDays;
      return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get days until expiry
  Future<int?> getDaysUntilExpiry(String storeId) async {
    try {
      final doc = await _firestore.collection('stores').doc(storeId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final expiresAt = data['verificationExpiresAt'] as Timestamp?;
      
      if (expiresAt == null) return null;

      return expiresAt.toDate().difference(DateTime.now()).inDays;
    } catch (e) {
      return null;
    }
  }
}

enum VerificationStatus {
  none,
  pending,
  verified,
  expired;

  static VerificationStatus fromString(String status) {
    final trimmedStatus = status.trim().toLowerCase();
    print('🔄 Converting status: "$status" -> "$trimmedStatus"');
    switch (trimmedStatus) {
      case 'pending':
        return VerificationStatus.pending;
      case 'verified':
        return VerificationStatus.verified;
      case 'expired':
        return VerificationStatus.expired;
      default:
        print('⚠️ Unknown status: "$trimmedStatus", returning none');
        return VerificationStatus.none;
    }
  }

  String get displayName {
    switch (this) {
      case VerificationStatus.none:
        return 'Not Verified';
      case VerificationStatus.pending:
        return 'Pending Verification';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.expired:
        return 'Expired';
    }
  }
}

/// Internal class for caching verification status
class _CachedStatus {
  final VerificationStatus status;
  final DateTime timestamp;

  _CachedStatus(this.status, this.timestamp);
}
