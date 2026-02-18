import 'package:cloud_firestore/cloud_firestore.dart';

/// Discount model for buyer app
class Discount {
  final String id;
  final String storeId;
  final String code;
  final String type; // 'percentage' or 'fixed'
  final num value;
  final int? usageLimit;
  final int usageCount;
  final String status;
  final DateTime? expiresAt;
  final List<String>? applicableProducts; // null means all products

  Discount({
    required this.id,
    required this.storeId,
    required this.code,
    required this.type,
    required this.value,
    this.usageLimit,
    required this.usageCount,
    required this.status,
    this.expiresAt,
    this.applicableProducts,
  });

  factory Discount.fromFirestore(DocumentSnapshot doc, String storeId) {
    final data = doc.data() as Map<String, dynamic>;
    return Discount(
      id: doc.id,
      storeId: storeId,
      code: data['code'] ?? '',
      type: data['type'] ?? 'percentage',
      value: data['value'] ?? 0,
      usageLimit: data['usageLimit'],
      usageCount: data['usageCount'] ?? 0,
      status: data['status'] ?? 'active',
      expiresAt: data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate() : null,
      applicableProducts: data['applicableProducts'] != null 
          ? List<String>.from(data['applicableProducts']) 
          : null,
    );
  }

  bool get isValid {
    if (status != 'active') return false;
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) return false;
    if (usageLimit != null && usageCount >= usageLimit!) return false;
    return true;
  }

  /// Calculate discount amount for a given subtotal
  double calculateDiscount(double subtotal) {
    if (type == 'percentage') {
      return subtotal * (value.toDouble() / 100);
    } else {
      // Fixed amount
      return value.toDouble();
    }
  }

  /// Check if discount applies to a specific product
  bool appliesToProduct(String productId) {
    if (applicableProducts == null) return true; // Applies to all
    return applicableProducts!.contains(productId);
  }
}

/// Service for validating and applying discounts
class DiscountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validate discount code for a specific store
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

      final discount = Discount.fromFirestore(snapshot.docs.first, storeId);
      
      if (!discount.isValid) return null;

      return discount;
    } catch (e) {
      print('Error validating discount: $e');
      return null;
    }
  }

  /// Increment usage count when discount is applied
  Future<void> incrementUsage(String storeId, String discountId) async {
    try {
      // First, get the current discount to check if it's still valid
      final discountDoc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('discounts')
          .doc(discountId)
          .get();

      if (!discountDoc.exists) {
        print('⚠️ Discount not found: $discountId');
        return;
      }

      final discount = Discount.fromFirestore(discountDoc, storeId);

      // Check if usage limit has been reached
      if (discount.usageLimit != null && discount.usageCount >= discount.usageLimit!) {
        print('⚠️ Discount usage limit reached: ${discount.usageCount}/${discount.usageLimit}');
        return;
      }

      // Increment usage count
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('discounts')
          .doc(discountId)
          .update({
        'usageCount': FieldValue.increment(1),
      });
      print('✅ Discount usage incremented: ${discount.usageCount + 1}/${discount.usageLimit ?? '∞'}');
    } catch (e) {
      print('Error incrementing discount usage: $e');
    }
  }
}
