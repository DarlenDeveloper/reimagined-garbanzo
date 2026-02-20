import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firestore Search Service
/// Provides search functionality for products, stores, and posts
class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  /// Search products by name, description, category, or store name
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase().trim();
      
      // Get all active products and filter in memory
      // This is a workaround since Firestore doesn't support full-text search
      final snapshot = await _firestore
          .collectionGroup('products')
          .where('isActive', isEqualTo: true)
          .limit(100) // Get more products to filter from
          .get();

      final results = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase();
        final category = (data['category'] ?? '').toString().toLowerCase();
        final storeName = (data['storeName'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();
        
        // Check if query matches any field
        if (name.contains(queryLower) || 
            category.contains(queryLower) || 
            storeName.contains(queryLower) ||
            description.contains(queryLower)) {
          data['id'] = doc.id;
          data['storeId'] = doc.reference.parent.parent?.id;
          results.add(data);
          
          // Limit results to 20
          if (results.length >= 20) break;
        }
      }

      return results;
    } catch (e) {
      print('❌ Search error: $e');
      return [];
    }
  }

  /// Search stores by name or description
  Future<List<Map<String, dynamic>>> searchStores(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase().trim();
      
      // Get all active stores and filter in memory (like products)
      final snapshot = await _firestore
          .collection('stores')
          .where('isActive', isEqualTo: true)
          .limit(50)
          .get();

      final results = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();
        
        // Check if query matches name or description
        if (name.contains(queryLower) || description.contains(queryLower)) {
          data['id'] = doc.id;
          results.add(data);
          
          // Limit results to 20
          if (results.length >= 20) break;
        }
      }

      return results;
    } catch (e) {
      print('❌ Store search error: $e');
      return [];
    }
  }

  /// Search posts by caption
  Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase().trim();
      
      final results = await _firestore
          .collection('posts')
          .orderBy('caption')
          .startAt([queryLower])
          .endAt(['$queryLower\uf8ff'])
          .limit(20)
          .get();

      return results.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Post search error: $e');
      return [];
    }
  }

  /// Get recent searches from local storage
  List<String> getRecentSearches() {
    // This is synchronous, so we return empty and load async
    // Call loadRecentSearches() to get actual data
    return [];
  }

  /// Load recent searches from SharedPreferences
  Future<List<String>> loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_recentSearchesKey) ?? [];
    } catch (e) {
      print('❌ Error loading recent searches: $e');
      return [];
    }
  }

  /// Get search suggestions (autocomplete) - returns product names only
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase().trim();
      
      // Get products and extract names
      final snapshot = await _firestore
          .collectionGroup('products')
          .where('isActive', isEqualTo: true)
          .limit(50)
          .get();

      final suggestions = <String>{};  // Use Set to avoid duplicates
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString();
        final nameLower = name.toLowerCase();
        
        // Check if name contains the query
        if (nameLower.contains(queryLower)) {
          suggestions.add(name);
          
          // Limit to 10 suggestions
          if (suggestions.length >= 10) break;
        }
      }

      return suggestions.toList();
    } catch (e) {
      print('❌ Suggestions error: $e');
      return [];
    }
  }

  /// Save search query to recent searches
  Future<void> saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> searches = prefs.getStringList(_recentSearchesKey) ?? [];
      
      // Remove if already exists
      searches.remove(query);
      
      // Add to beginning
      searches.insert(0, query);
      
      // Keep only last N searches
      if (searches.length > _maxRecentSearches) {
        searches = searches.sublist(0, _maxRecentSearches);
      }
      
      await prefs.setStringList(_recentSearchesKey, searches);
    } catch (e) {
      print('❌ Error saving recent search: $e');
    }
  }

  /// Clear recent searches
  Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (e) {
      print('❌ Error clearing recent searches: $e');
    }
  }
}
