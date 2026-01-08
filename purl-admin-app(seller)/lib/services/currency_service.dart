import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Currency data model
class CurrencyData {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const CurrencyData({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });
}

/// Service for managing store currency preferences
/// 
/// FIRESTORE STRUCTURE:
/// /storeCurrencies/{storeId}
/// ├── currency: string (e.g., 'KES', 'USD')
/// ├── updatedAt: timestamp
/// 
/// This is stored separately from the store document to allow
/// for easy querying and to avoid touching the main store document.
class CurrencyService extends ChangeNotifier {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _storeId;
  String _selectedCurrency = 'KES';
  bool _isInitialized = false;
  bool _hasCurrencySet = false;

  /// All supported currencies
  static const Map<String, CurrencyData> currencies = {
    'KES': CurrencyData(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling', flag: '🇰🇪'),
    'USD': CurrencyData(code: 'USD', symbol: '\$', name: 'US Dollar', flag: '🇺🇸'),
    'EUR': CurrencyData(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺'),
    'GBP': CurrencyData(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧'),
    'NGN': CurrencyData(code: 'NGN', symbol: '₦', name: 'Nigerian Naira', flag: '🇳🇬'),
    'GHS': CurrencyData(code: 'GHS', symbol: 'GH₵', name: 'Ghanaian Cedi', flag: '🇬🇭'),
    'UGX': CurrencyData(code: 'UGX', symbol: 'USh', name: 'Ugandan Shilling', flag: '🇺🇬'),
    'TZS': CurrencyData(code: 'TZS', symbol: 'TSh', name: 'Tanzanian Shilling', flag: '🇹🇿'),
    'ZAR': CurrencyData(code: 'ZAR', symbol: 'R', name: 'South African Rand', flag: '🇿🇦'),
    'RWF': CurrencyData(code: 'RWF', symbol: 'FRw', name: 'Rwandan Franc', flag: '🇷🇼'),
    'ETB': CurrencyData(code: 'ETB', symbol: 'Br', name: 'Ethiopian Birr', flag: '🇪🇹'),
    'AED': CurrencyData(code: 'AED', symbol: 'AED', name: 'UAE Dirham', flag: '🇦🇪'),
    'SAR': CurrencyData(code: 'SAR', symbol: 'SAR', name: 'Saudi Riyal', flag: '🇸🇦'),
    'INR': CurrencyData(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳'),
    'CNY': CurrencyData(code: 'CNY', symbol: '¥', name: 'Chinese Yuan', flag: '🇨🇳'),
    'JPY': CurrencyData(code: 'JPY', symbol: '¥', name: 'Japanese Yen', flag: '🇯🇵'),
  };

  /// Get current store ID
  String? get storeId => _storeId;

  /// Get current currency code
  String get currentCurrency => _selectedCurrency;

  /// Check if store has a currency set
  bool get hasCurrencySet => _hasCurrencySet;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get current currency data
  CurrencyData get currentCurrencyData => 
      currencies[_selectedCurrency] ?? currencies['KES']!;

  /// Get currency symbol
  String get symbol => currentCurrencyData.symbol;

  /// Initialize the service with a store ID
  /// Call this after user logs in and store is determined
  Future<void> init([String? storeId]) async {
    if (storeId != null) {
      _storeId = storeId;
    }

    if (_storeId == null) {
      _isInitialized = true;
      _hasCurrencySet = false;
      return;
    }

    try {
      final doc = await _firestore
          .collection('storeCurrencies')
          .doc(_storeId)
          .get();

      if (doc.exists && doc.data()?['currency'] != null) {
        _selectedCurrency = doc.data()!['currency'] as String;
        _hasCurrencySet = true;
      } else {
        _hasCurrencySet = false;
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isInitialized = true;
      _hasCurrencySet = false;
      debugPrint('CurrencyService init error: $e');
    }
  }

  /// Set the store's currency
  /// This saves to Firestore and updates local state
  Future<void> setCurrency(String currencyCode) async {
    if (!currencies.containsKey(currencyCode)) return;
    if (_storeId == null) return;

    try {
      await _firestore.collection('storeCurrencies').doc(_storeId).set({
        'currency': currencyCode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _selectedCurrency = currencyCode;
      _hasCurrencySet = true;
      notifyListeners();
    } catch (e) {
      debugPrint('CurrencyService setCurrency error: $e');
      rethrow;
    }
  }

  /// Get currency for a specific store (useful for buyer app)
  Future<String> getStoreCurrency(String storeId) async {
    try {
      final doc = await _firestore
          .collection('storeCurrencies')
          .doc(storeId)
          .get();

      if (doc.exists && doc.data()?['currency'] != null) {
        return doc.data()!['currency'] as String;
      }
      return 'KES'; // Default
    } catch (e) {
      return 'KES';
    }
  }

  /// Format a price with the current currency symbol
  String formatPrice(num price) {
    final data = currentCurrencyData;

    // Format based on currency (some currencies don't use decimals)
    if (['JPY', 'KES', 'UGX', 'TZS', 'RWF', 'NGN'].contains(_selectedCurrency)) {
      return '${data.symbol} ${_formatNumber(price.round())}';
    }

    return '${data.symbol} ${_formatNumber(price, decimals: 2)}';
  }

  /// Format a price with a specific currency
  String formatPriceWithCurrency(num price, String currencyCode) {
    final data = currencies[currencyCode] ?? currencies['KES']!;

    if (['JPY', 'KES', 'UGX', 'TZS', 'RWF', 'NGN'].contains(currencyCode)) {
      return '${data.symbol} ${_formatNumber(price.round())}';
    }

    return '${data.symbol} ${_formatNumber(price, decimals: 2)}';
  }

  /// Format number with thousand separators
  String _formatNumber(num value, {int decimals = 0}) {
    final parts = value.toStringAsFixed(decimals).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );

    if (decimals > 0 && parts.length > 1) {
      return '$intPart.${parts[1]}';
    }
    return intPart;
  }

  /// Reset service (call on logout)
  void reset() {
    _storeId = null;
    _selectedCurrency = 'KES';
    _isInitialized = false;
    _hasCurrencySet = false;
    notifyListeners();
  }
}
