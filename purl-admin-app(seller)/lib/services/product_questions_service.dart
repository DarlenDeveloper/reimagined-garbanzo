import 'package:cloud_firestore/cloud_firestore.dart';

/// ProductQuestionsService manages product Q&A functionality for sellers
/// 
/// FIRESTORE STRUCTURE:
/// /stores/{storeId}/products/{productId}/questions/{questionId}
/// ├── userId: string
/// ├── userName: string
/// ├── userPhotoUrl: string?
/// ├── question: string
/// ├── answer: string?
/// ├── answeredAt: timestamp?
/// ├── answeredBy: string? (storeId)
/// ├── createdAt: timestamp
/// ├── upvotes: number
/// ├── isPublic: boolean
class ProductQuestionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Answer a question (seller only)
  Future<void> answerQuestion({
    required String storeId,
    required String productId,
    required String questionId,
    required String answer,
  }) async {
    await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .doc(productId)
        .collection('questions')
        .doc(questionId)
        .update({
      'answer': answer,
      'answeredAt': Timestamp.now(),
      'answeredBy': storeId,
    });
  }

  /// Update an existing answer
  Future<void> updateAnswer({
    required String storeId,
    required String productId,
    required String questionId,
    required String answer,
  }) async {
    await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .doc(productId)
        .collection('questions')
        .doc(questionId)
        .update({
      'answer': answer,
      'answeredAt': Timestamp.now(),
    });
  }

  /// Get all questions for a store (across all products)
  Future<List<Map<String, dynamic>>> getAllStoreQuestions({
    required String storeId,
    bool? answered,
    int limit = 50,
  }) async {
    print('🔍 [Questions] Getting questions for storeId: $storeId');
    print('🔍 [Questions] Filter - answered: $answered');
    print('🔍 [Questions] Firestore path: /stores/$storeId/products');
    
    final productsSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .get();

    print('🔍 [Questions] Found ${productsSnapshot.docs.length} products');
    
    if (productsSnapshot.docs.isEmpty) {
      print('⚠️ [Questions] No products found! Check if:');
      print('   1. Products exist at /stores/$storeId/products');
      print('   2. The storeId matches your seller account');
    }

    final List<Map<String, dynamic>> allQuestions = [];

    for (var productDoc in productsSnapshot.docs) {
      final productId = productDoc.id;
      final productData = productDoc.data();
      final productName = productData['name'] ?? 'Unknown Product';

      print('🔍 [Questions] Checking product: $productName (ID: $productId)');

      var questionsQuery = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc(productId)
          .collection('questions')
          .where('isPublic', isEqualTo: true);

      final questionsSnapshot = await questionsQuery.get();
      
      print('🔍 [Questions] Product "$productName" has ${questionsSnapshot.docs.length} questions');

      for (var questionDoc in questionsSnapshot.docs) {
        final data = questionDoc.data();
        final hasAnswer = data['answer'] != null && (data['answer'] as String).isNotEmpty;

        print('🔍 [Questions] Question: "${data['question']}" - hasAnswer: $hasAnswer');

        // Filter by answered status if specified
        if (answered != null && hasAnswer != answered) {
          print('🔍 [Questions] Skipping question (filter mismatch)');
          continue;
        }

        data['id'] = questionDoc.id;
        data['productId'] = productId;
        data['productName'] = productName;
        allQuestions.add(data);
        
        print('🔍 [Questions] Added question to list');
      }
    }

    print('🔍 [Questions] Total questions found: ${allQuestions.length}');

    // Sort by createdAt descending (newest first)
    allQuestions.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    final result = allQuestions.take(limit).toList();
    print('🔍 [Questions] Returning ${result.length} questions after limit');
    
    return result;
  }

  /// Get questions for a specific product
  Stream<List<Map<String, dynamic>>> getProductQuestions({
    required String storeId,
    required String productId,
    int limit = 20,
  }) {
    return _firestore
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .doc(productId)
        .collection('questions')
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['productId'] = productId;
        return data;
      }).toList();
    });
  }

  /// Get unanswered question count for a store
  Future<int> getUnansweredCount({required String storeId}) async {
    final productsSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .get();

    int totalUnanswered = 0;

    for (var productDoc in productsSnapshot.docs) {
      final questionsSnapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('products')
          .doc(productDoc.id)
          .collection('questions')
          .where('isPublic', isEqualTo: true)
          .get();

      for (var questionDoc in questionsSnapshot.docs) {
        final data = questionDoc.data();
        final hasAnswer = data['answer'] != null && (data['answer'] as String).isNotEmpty;
        if (!hasAnswer) totalUnanswered++;
      }
    }

    return totalUnanswered;
  }

  /// Get unanswered question count for a specific product
  Future<int> getProductUnansweredCount({
    required String storeId,
    required String productId,
  }) async {
    final questionsSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .doc(productId)
        .collection('questions')
        .where('isPublic', isEqualTo: true)
        .get();

    int unanswered = 0;
    for (var doc in questionsSnapshot.docs) {
      final data = doc.data();
      final hasAnswer = data['answer'] != null && (data['answer'] as String).isNotEmpty;
      if (!hasAnswer) unanswered++;
    }

    return unanswered;
  }

  /// Delete a question
  Future<void> deleteQuestion({
    required String storeId,
    required String productId,
    required String questionId,
  }) async {
    await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .doc(productId)
        .collection('questions')
        .doc(questionId)
        .delete();
  }

  /// Format time ago
  String getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
