import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Discount model
class Discount {
  final String id;
  final String code;
  final String type; // 'percentage' or 'fixed'
  final num value;
  final int? usageLimit;
  final int usageCount;
  final String status; // 'active' or 'expired'
  final DateTime? expiresAt;
  final DateTime createdAt;

  Discount({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.usageLimit,
    required this.usageCount,
    required this.status,
    this.expiresAt,
    required this.createdAt,
  });

  factory Discount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Discount(
      id: doc.id,
      code: data['code'] ?? '',
      type: data['type'] ?? 'percentage',
      value: data['value'] ?? 0,
      usageLimit: data['usageLimit'],
      usageCount: data['usageCount'] ?? 0,
      status: data['status'] ?? 'active',
      expiresAt: data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate() : null,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'type': type,
      'value': value,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'status': status,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Get days left until expiry
  String getExpiryText() {
    if (status == 'expired') return 'Ended';
    if (expiresAt == null) return 'No expiry';
    
    final now = DateTime.now();
    final difference = expiresAt!.difference(now);
    
    if (difference.isNegative) return 'Ended';
    if (difference.inDays == 0) return 'Expires today';
    if (difference.inDays == 1) return '1 day left';
    return '${difference.inDays} days left';
  }

  /// Get usage text
  String getUsageText() {
    if (usageLimit == null) return '$usageCount/∞';
    return '$usageCount/$usageLimit';
  }

  /// Check if discount is still valid
  bool get isValid {
    if (status == 'expired') return false;
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) return false;
    if (usageLimit != null && usageCount >= usageLimit!) return false;
    return true;
  }
}

/// Service for managing store discounts
class DiscountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get discounts stream for a store
  Stream<List<Discount>> getDiscountsStream(String storeId) {
    return _firestore
        .collection('stores')
        .doc(storeId)
        .collection('discounts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Discount.fromFirestore(doc)).toList());
  }

  /// Create a new discount
  Future<void> createDiscount({
    required String storeId,
    required String code,
    required String type,
    required num value,
    int? usageLimit,
    DateTime? expiresAt,
  }) async {
    try {
      final discount = Discount(
        id: '',
        code: code.toUpperCase(),
        type: type,
        value: value,
        usageLimit: usageLimit,
        usageCount: 0,
        status: 'active',
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('discounts')
          .add(discount.toFirestore());
    } catch (e) {
      debugPrint('Error creating discount: $e');
      rethrow;
    }
  }

  /// Update discount status
  Future<void> updateDiscountStatus(String storeId, String discountId, String status) async {
    try {
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('discounts')
          .doc(discountId)
          .update({'status': status});
    } catch (e) {
      debugPrint('Error updating discount status: $e');
      rethrow;
    }
  }

  /// Delete a discount
  Future<void> deleteDiscount(String storeId, String discountId) async {
    try {
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('discounts')
          .doc(discountId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting discount: $e');
      rethrow;
    }
  }

  /// Increment usage count
  Future<void> incrementUsage(String storeId, String discountId) async {
    try {
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('discounts')
          .doc(discountId)
          .update({
        'usageCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing usage: $e');
      rethrow;
    }
  }

  /// Validate and apply discount code
  Future<Discount?> validateDiscountCode(String storeId, String code) async {
    try {
      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('discounts')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final discount = Discount.fromFirestore(snapshot.docs.first);
      
      // Check if valid
      if (!discount.isValid) return null;

      return discount;
    } catch (e) {
      debugPrint('Error validating discount: $e');
      return null;
    }
  }

  /// Auto-expire discounts (call this periodically or via cloud function)
  Future<void> autoExpireDiscounts(String storeId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('discounts')
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in snapshot.docs) {
        final discount = Discount.fromFirestore(doc);
        
        // Check if expired by date
        if (discount.expiresAt != null && discount.expiresAt!.isBefore(now)) {
          await updateDiscountStatus(storeId, discount.id, 'expired');
        }
        
        // Check if expired by usage
        if (discount.usageLimit != null && discount.usageCount >= discount.usageLimit!) {
          await updateDiscountStatus(storeId, discount.id, 'expired');
        }
      }
    } catch (e) {
      debugPrint('Error auto-expiring discounts: $e');
    }
  }
}
