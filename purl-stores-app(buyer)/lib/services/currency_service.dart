import 'package:cloud_firestore/cloud_firestore.dart';

/// Currency data model
class CurrencyData {
  final String code;
  final String symbol;
  final String name;

  const CurrencyData({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

/// Currency service for buyer app
/// Formats prices based on store currency
class CurrencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache store currencies
  final Map<String, String> _currencyCache = {};

  /// All supported currencies
  static const Map<String, CurrencyData> currencies = {
    'KES': CurrencyData(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling'),
    'USD': CurrencyData(code: 'USD', symbol: '\$', name: 'US Dollar'),
    'EUR': CurrencyData(code: 'EUR', symbol: '€', name: 'Euro'),
    'GBP': CurrencyData(code: 'GBP', symbol: '£', name: 'British Pound'),
    'NGN': CurrencyData(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
    'GHS': CurrencyData(code: 'GHS', symbol: 'GH₵', name: 'Ghanaian Cedi'),
    'UGX': CurrencyData(code: 'UGX', symbol: 'USh', name: 'Ugandan Shilling'),
    'TZS': CurrencyData(code: 'TZS', symbol: 'TSh', name: 'Tanzanian Shilling'),
    'ZAR': CurrencyData(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
    'RWF': CurrencyData(code: 'RWF', symbol: 'FRw', name: 'Rwandan Franc'),
    'ETB': CurrencyData(code: 'ETB', symbol: 'Br', name: 'Ethiopian Birr'),
    'AED': CurrencyData(code: 'AED', symbol: 'AED', name: 'UAE Dirham'),
    'SAR': CurrencyData(code: 'SAR', symbol: 'SAR', name: 'Saudi Riyal'),
    'INR': CurrencyData(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    'CNY': CurrencyData(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    'JPY': CurrencyData(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  };

  /// Get store currency (with caching)
  Future<String> getStoreCurrency(String storeId) async {
    if (_currencyCache.containsKey(storeId)) {
      return _currencyCache[storeId]!;
    }

    try {
      final doc = await _firestore
          .collection('storeCurrencies')
          .doc(storeId)
          .get();

      if (doc.exists && doc.data()?['currency'] != null) {
        final currency = doc.data()!['currency'] as String;
        _currencyCache[storeId] = currency;
        return currency;
      }
    } catch (e) {
      // Ignore errors
    }

    return 'KES'; // Default
  }

  /// Format price with currency symbol
  String formatPrice(num price, String currencyCode) {
    final data = currencies[currencyCode] ?? currencies['KES']!;

    // Format based on currency (some currencies don't use decimals)
    if (['JPY', 'KES', 'UGX', 'TZS', 'RWF', 'NGN'].contains(currencyCode)) {
      return '${data.symbol} ${_formatNumber(price.round())}';
    }

    return '${data.symbol}${_formatNumber(price, decimals: 2)}';
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

  /// Clear cache
  void clearCache() {
    _currencyCache.clear();
  }
}
