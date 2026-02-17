import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get store ID for current user
  Future<String?> _getStoreId() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final storesSnapshot = await _firestore
        .collection('stores')
        .where('authorizedUsers', arrayContains: userId)
        .limit(1)
        .get();

    if (storesSnapshot.docs.isEmpty) return null;
    return storesSnapshot.docs.first.id;
  }

  /// Get date range based on period
  Map<String, DateTime> _getDateRange(String period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (period) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'Last Week':
        final lastWeekEnd = now.subtract(Duration(days: now.weekday));
        endDate = DateTime(lastWeekEnd.year, lastWeekEnd.month, lastWeekEnd.day, 23, 59, 59);
        startDate = endDate.subtract(const Duration(days: 6));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate = lastMonth;
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    return {'start': startDate, 'end': endDate};
  }

  /// Get overview metrics
  Future<Map<String, dynamic>> getOverviewMetrics(String period) async {
    final storeId = await _getStoreId();
    if (storeId == null) {
      return {
        'revenue': 0.0,
        'orders': 0,
        'visitors': 0,
        'conversion': 0.0,
        'revenueChange': 0.0,
        'ordersChange': 0.0,
      };
    }

    final dateRange = _getDateRange(period);
    final startDate = Timestamp.fromDate(dateRange['start']!);
    final endDate = Timestamp.fromDate(dateRange['end']!);

    // Get orders for current period
    final ordersSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .get();

    double revenue = 0.0;
    int orders = ordersSnapshot.docs.length;

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      revenue += (data['total'] ?? 0).toDouble();
    }

    // Get previous period for comparison
    final periodDuration = dateRange['end']!.difference(dateRange['start']!);
    final prevStartDate = Timestamp.fromDate(dateRange['start']!.subtract(periodDuration));
    final prevEndDate = Timestamp.fromDate(dateRange['start']!.subtract(const Duration(seconds: 1)));

    final prevOrdersSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: prevStartDate)
        .where('createdAt', isLessThanOrEqualTo: prevEndDate)
        .get();

    double prevRevenue = 0.0;
    int prevOrders = prevOrdersSnapshot.docs.length;

    for (var doc in prevOrdersSnapshot.docs) {
      final data = doc.data();
      prevRevenue += (data['total'] ?? 0).toDouble();
    }

    // Calculate changes
    double revenueChange = prevRevenue > 0 ? ((revenue - prevRevenue) / prevRevenue * 100) : 0.0;
    double ordersChange = prevOrders > 0 ? ((orders - prevOrders) / prevOrders * 100) : 0.0;

    // Estimate visitors (orders * 20 as rough estimate - 5% conversion)
    int visitors = orders * 20;
    double conversion = visitors > 0 ? (orders / visitors * 100) : 0.0;

    return {
      'revenue': revenue,
      'orders': orders,
      'visitors': visitors,
      'conversion': conversion,
      'revenueChange': revenueChange,
      'ordersChange': ordersChange,
    };
  }

  /// Get daily revenue data for chart
  Future<List<double>> getDailyRevenue(String period) async {
    final storeId = await _getStoreId();
    if (storeId == null) return List.filled(7, 0.0);

    final dateRange = _getDateRange(period);
    final startDate = dateRange['start']!;
    final endDate = dateRange['end']!;

    // Get all orders in range
    final ordersSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    // Group by day
    Map<int, double> dailyRevenue = {};
    final days = endDate.difference(startDate).inDays + 1;

    for (int i = 0; i < days; i++) {
      dailyRevenue[i] = 0.0;
    }

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      final dayIndex = createdAt.difference(startDate).inDays;
      
      if (dayIndex >= 0 && dayIndex < days) {
        dailyRevenue[dayIndex] = (dailyRevenue[dayIndex] ?? 0.0) + (data['total'] ?? 0).toDouble();
      }
    }

    // Return last 7 days
    return List.generate(
      days > 7 ? 7 : days,
      (i) => dailyRevenue[days > 7 ? days - 7 + i : i] ?? 0.0,
    );
  }

  /// Get recent activity (latest orders)
  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final storeId = await _getStoreId();
    if (storeId == null) return [];

    final ordersSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    return ordersSnapshot.docs.map((doc) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final now = DateTime.now();
      String timeAgo = 'Just now';

      if (createdAt != null) {
        final difference = now.difference(createdAt);
        if (difference.inMinutes < 60) {
          timeAgo = '${difference.inMinutes} min ago';
        } else if (difference.inHours < 24) {
          timeAgo = '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
        } else {
          timeAgo = '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
        }
      }

      final items = data['items'] as List<dynamic>? ?? [];
      final itemCount = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 0));

      return {
        'orderNumber': data['orderNumber'] ?? 'N/A',
        'total': (data['total'] ?? 0).toDouble(),
        'itemCount': itemCount,
        'timeAgo': timeAgo,
      };
    }).toList();
  }

  /// Get quick stats
  Future<Map<String, dynamic>> getQuickStats(String period) async {
    final storeId = await _getStoreId();
    if (storeId == null) {
      return {
        'avgOrder': 0.0,
        'itemsPerOrder': 0.0,
        'returnRate': 0.0,
      };
    }

    final dateRange = _getDateRange(period);
    final startDate = Timestamp.fromDate(dateRange['start']!);
    final endDate = Timestamp.fromDate(dateRange['end']!);

    final ordersSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .get();

    if (ordersSnapshot.docs.isEmpty) {
      return {
        'avgOrder': 0.0,
        'itemsPerOrder': 0.0,
        'returnRate': 0.0,
      };
    }

    double totalRevenue = 0.0;
    int totalItems = 0;
    int returnedOrders = 0;

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      totalRevenue += (data['total'] ?? 0).toDouble();
      
      final items = data['items'] as List<dynamic>? ?? [];
      totalItems += items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 0));
      
      if (data['status'] == 'returned' || data['status'] == 'refunded') {
        returnedOrders++;
      }
    }

    final avgOrder = totalRevenue / ordersSnapshot.docs.length;
    final itemsPerOrder = totalItems / ordersSnapshot.docs.length;
    final returnRate = (returnedOrders / ordersSnapshot.docs.length) * 100;

    return {
      'avgOrder': avgOrder,
      'itemsPerOrder': itemsPerOrder,
      'returnRate': returnRate,
    };
  }

  /// Get sales breakdown (product sales, shipping, tips)
  Future<Map<String, dynamic>> getSalesBreakdown(String period) async {
    final storeId = await _getStoreId();
    if (storeId == null) {
      return {
        'productSales': 0.0,
        'shippingFees': 0.0,
        'tips': 0.0,
        'total': 0.0,
      };
    }

    final dateRange = _getDateRange(period);
    final startDate = Timestamp.fromDate(dateRange['start']!);
    final endDate = Timestamp.fromDate(dateRange['end']!);

    final ordersSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .get();

    double productSales = 0.0;
    double shippingFees = 0.0;
    double tips = 0.0;

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      
      // Calculate product sales (subtotal or total minus delivery)
      final subtotal = (data['subtotal'] ?? data['total'] ?? 0).toDouble();
      productSales += subtotal;
      
      // Add shipping/delivery fees
      final deliveryFee = (data['deliveryFee'] ?? 0).toDouble();
      shippingFees += deliveryFee;
      
      // Add tips if available
      final tip = (data['tip'] ?? 0).toDouble();
      tips += tip;
    }

    final total = productSales + shippingFees + tips;

    return {
      'productSales': productSales,
      'shippingFees': shippingFees,
      'tips': tips,
      'total': total,
    };
  }

  /// Get payment methods breakdown
  Future<Map<String, int>> getPaymentMethods(String period) async {
    final storeId = await _getStoreId();
    if (storeId == null) {
      return {
        'mobileMoney': 0,
        'card': 0,
        'cash': 0,
      };
    }

    final dateRange = _getDateRange(period);
    final startDate = Timestamp.fromDate(dateRange['start']!);
    final endDate = Timestamp.fromDate(dateRange['end']!);

    final ordersSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .get();

    Map<String, int> paymentMethods = {
      'mobileMoney': 0,
      'card': 0,
      'cash': 0,
    };

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      final paymentMethod = (data['paymentMethod'] ?? 'cash').toString().toLowerCase();
      
      if (paymentMethod.contains('mobile') || paymentMethod.contains('momo')) {
        paymentMethods['mobileMoney'] = (paymentMethods['mobileMoney'] ?? 0) + 1;
      } else if (paymentMethod.contains('card')) {
        paymentMethods['card'] = (paymentMethods['card'] ?? 0) + 1;
      } else {
        paymentMethods['cash'] = (paymentMethods['cash'] ?? 0) + 1;
      }
    }

    return paymentMethods;
  }

  /// Get daily sales data for chart (same as daily revenue but returns list)
  Future<List<double>> getDailySales(String period) async {
    return getDailyRevenue(period);
  }

  /// Get product stats (total, active, low stock)
  Future<Map<String, int>> getProductStats() async {
    final storeId = await _getStoreId();
    if (storeId == null) {
      return {
        'total': 0,
        'active': 0,
        'lowStock': 0,
      };
    }

    final productsSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('products')
        .get();

    int total = productsSnapshot.docs.length;
    int active = 0;
    int lowStock = 0;

    for (var doc in productsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] ?? 'active';
      final stock = (data['stock'] ?? 0) as int;

      if (status == 'active') {
        active++;
      }

      if (stock < 10 && stock > 0) {
        lowStock++;
      }
    }

    return {
      'total': total,
      'active': active,
      'lowStock': lowStock,
    };
  }

  /// Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts(String period) async {
    final storeId = await _getStoreId();
    if (storeId == null) return [];

    final dateRange = _getDateRange(period);
    final startDate = Timestamp.fromDate(dateRange['start']!);
    final endDate = Timestamp.fromDate(dateRange['end']!);

    final ordersSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .get();

    // Count sales per product
    Map<String, Map<String, dynamic>> productSales = {};

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      final items = data['items'] as List<dynamic>? ?? [];

      for (var item in items) {
        final productId = item['productId'] ?? '';
        final productName = item['productName'] ?? 'Unknown Product';
        final quantity = (item['quantity'] ?? 0) as int;
        final price = (item['price'] ?? 0).toDouble();
        final revenue = quantity * price;

        if (productSales.containsKey(productId)) {
          productSales[productId]!['sales'] += quantity;
          productSales[productId]!['revenue'] += revenue;
          productSales[productId]!['orderCount'] = (productSales[productId]!['orderCount'] ?? 0) + 1;
        } else {
          productSales[productId] = {
            'productId': productId,
            'name': productName,
            'sales': quantity,
            'revenue': revenue,
            'orderCount': 1,
          };
        }
      }
    }

    // Convert to list and sort by order count (not quantity)
    final topProducts = productSales.values.toList();
    topProducts.sort((a, b) => (b['orderCount'] as int).compareTo(a['orderCount'] as int));

    // Calculate growth (mock for now - would need historical data)
    return topProducts.take(5).map((product) {
      return {
        'name': product['name'],
        'sales': product['orderCount'], // Number of orders, not quantity
        'revenue': product['revenue'],
        'growth': 0, // Would need previous period data
      };
    }).toList();
  }

  /// Get category performance
  Future<List<Map<String, dynamic>>> getCategoryPerformance(String period) async {
    final storeId = await _getStoreId();
    if (storeId == null) return [];

    final dateRange = _getDateRange(period);
    final startDate = Timestamp.fromDate(dateRange['start']!);
    final endDate = Timestamp.fromDate(dateRange['end']!);

    final ordersSnapshot = await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .get();

    // Get all unique product IDs from orders
    Set<String> productIds = {};
    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      final items = data['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        final productId = item['productId'] ?? '';
        if (productId.isNotEmpty) {
          productIds.add(productId);
        }
      }
    }

    // Fetch product details to get categories
    Map<String, String> productCategories = {};
    for (var productId in productIds) {
      try {
        final productDoc = await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('products')
            .doc(productId)
            .get();
        
        if (productDoc.exists) {
          final productData = productDoc.data();
          final categoryId = productData?['categoryId'] ?? '';
          productCategories[productId] = categoryId;
        }
      } catch (e) {
        // Skip if product not found
      }
    }

    // Count sales per category
    Map<String, Map<String, dynamic>> categorySales = {};

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      final items = data['items'] as List<dynamic>? ?? [];

      for (var item in items) {
        final productId = item['productId'] ?? '';
        final categoryId = productCategories[productId] ?? 'uncategorized';
        final quantity = (item['quantity'] ?? 0) as int;
        final price = (item['price'] ?? 0).toDouble();
        final revenue = quantity * price;

        if (categorySales.containsKey(categoryId)) {
          categorySales[categoryId]!['sales'] += revenue;
          categorySales[categoryId]!['orders'] += 1;
        } else {
          categorySales[categoryId] = {
            'categoryId': categoryId,
            'sales': revenue,
            'orders': 1,
          };
        }
      }
    }

    // Convert to list and calculate percentages
    final categories = categorySales.values.toList();
    categories.sort((a, b) => (b['sales'] as double).compareTo(a['sales'] as double));

    final totalSales = categories.fold<double>(0, (sum, cat) => sum + (cat['sales'] as double));

    return categories.take(3).map((cat) {
      final percentage = totalSales > 0 ? ((cat['sales'] as double) / totalSales * 100).round() : 0;
      final categoryId = cat['categoryId'] as String;
      
      // Get category name from ID (you may need to import CategoryTaxonomy)
      String categoryName = categoryId;
      if (categoryId != 'uncategorized') {
        // Try to get readable category name
        categoryName = _getCategoryName(categoryId);
      } else {
        categoryName = 'Uncategorized';
      }
      
      return {
        'category': categoryName,
        'sales': cat['sales'],
        'orders': cat['orders'],
        'percentage': percentage,
      };
    }).toList();
  }

  /// Helper to get category name from ID
  String _getCategoryName(String categoryId) {
    // Map of common category IDs to names
    final categoryNames = {
      'electronics': 'Electronics',
      'fashion': 'Fashion',
      'home': 'Home & Living',
      'beauty': 'Beauty & Personal Care',
      'sports': 'Sports & Outdoors',
      'toys': 'Toys & Games',
      'books': 'Books & Media',
      'food': 'Food & Beverages',
      'health': 'Health & Wellness',
      'automotive': 'Automotive',
      'pets': 'Pet Supplies',
      'office': 'Office Supplies',
      'garden': 'Garden & Outdoor',
      'baby': 'Baby & Kids',
      'jewelry': 'Jewelry & Accessories',
    };
    
    return categoryNames[categoryId.toLowerCase()] ?? categoryId;
  }
}
