import 'package:cloud_firestore/cloud_firestore.dart';

/// ProductQuestionsService manages product Q&A functionality
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

  /// Ask a question about a product
  Future<String> askQuestion({
    required String storeId,
    required String productId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String question,
  }) async {
    final questionRef = _firestore
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .doc(productId)
        .collection('questions')
        .doc();

    await questionRef.set({
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl ?? '',
      'question': question,
      'answer': null,
      'answeredAt': null,
      'answeredBy': null,
      'createdAt': Timestamp.now(),
      'upvotes': 0,
      'isPublic': true,
    });

    return questionRef.id;
  }

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

  /// Get questions for a product
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
        return data;
      }).toList();
    });
  }

  /// Upvote a question
  Future<void> upvoteQuestion({
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
        .update({
      'upvotes': FieldValue.increment(1),
    });
  }

  /// Delete a question (user or seller)
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

  /// Get question count for a product
  Future<int> getQuestionCount({
    required String storeId,
    required String productId,
  }) async {
    final snapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .doc(productId)
        .collection('questions')
        .where('isPublic', isEqualTo: true)
        .count()
        .get();

    return snapshot.count ?? 0;
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
