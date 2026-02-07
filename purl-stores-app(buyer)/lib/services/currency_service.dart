import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Currency data model
class CurrencyData {
  final String code;
  final String symbol;
  final String name;
  final double rateToUSD; // Exchange rate to USD

  const CurrencyData({
    required this.code,
    required this.symbol,
    required this.name,
    required this.rateToUSD,
  });
}

/// Currency service for buyer app
/// Converts and formats prices based on user's preferred currency
class CurrencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache
  final Map<String, String> _currencyCache = {};
  String? _userCurrency;

  /// All supported currencies with exchange rates (as of Jan 2026)
  static const Map<String, CurrencyData> currencies = {
    'USD': CurrencyData(code: 'USD', symbol: '\$', name: 'US Dollar', rateToUSD: 1.0),
    'EUR': CurrencyData(code: 'EUR', symbol: '€', name: 'Euro', rateToUSD: 0.92),
    'GBP': CurrencyData(code: 'GBP', symbol: '£', name: 'British Pound', rateToUSD: 0.79),
    'KES': CurrencyData(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling', rateToUSD: 129.0),
    'UGX': CurrencyData(code: 'UGX', symbol: 'USh', name: 'Ugandan Shilling', rateToUSD: 3700.0),
    'TZS': CurrencyData(code: 'TZS', symbol: 'TSh', name: 'Tanzanian Shilling', rateToUSD: 2500.0),
    'NGN': CurrencyData(code: 'NGN', symbol: '₦', name: 'Nigerian Naira', rateToUSD: 1500.0),
    'GHS': CurrencyData(code: 'GHS', symbol: 'GH₵', name: 'Ghanaian Cedi', rateToUSD: 15.0),
    'ZAR': CurrencyData(code: 'ZAR', symbol: 'R', name: 'South African Rand', rateToUSD: 18.0),
    'RWF': CurrencyData(code: 'RWF', symbol: 'FRw', name: 'Rwandan Franc', rateToUSD: 1300.0),
    'ETB': CurrencyData(code: 'ETB', symbol: 'Br', name: 'Ethiopian Birr', rateToUSD: 120.0),
    'AED': CurrencyData(code: 'AED', symbol: 'AED', name: 'UAE Dirham', rateToUSD: 3.67),
    'SAR': CurrencyData(code: 'SAR', symbol: 'SAR', name: 'Saudi Riyal', rateToUSD: 3.75),
    'INR': CurrencyData(code: 'INR', symbol: '₹', name: 'Indian Rupee', rateToUSD: 83.0),
    'CNY': CurrencyData(code: 'CNY', symbol: '¥', name: 'Chinese Yuan', rateToUSD: 7.2),
    'JPY': CurrencyData(code: 'JPY', symbol: '¥', name: 'Japanese Yen', rateToUSD: 150.0),
  };

  /// Get user's preferred currency
  Future<String> getUserCurrency({bool forceRefresh = false}) async {
    if (_userCurrency != null && !forceRefresh) return _userCurrency!;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 'UGX'; // Default

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data()?['currency'] != null) {
        _userCurrency = doc.data()!['currency'] as String;
        return _userCurrency!;
      }
    } catch (e) {
      // Ignore errors
    }

    return 'UGX'; // Default
  }

  /// Update user currency and clear cache
  Future<void> updateUserCurrency(String currency) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Update cache FIRST before saving to Firestore
    _userCurrency = currency;
    _currencyCache.clear();

    // Then save to Firestore
    await _firestore.collection('users').doc(userId).update({
      'currency': currency,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Convert price from one currency to another
  double convertPrice(num price, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return price.toDouble();

    final fromData = currencies[fromCurrency];
    final toData = currencies[toCurrency];

    if (fromData == null || toData == null) return price.toDouble();

    // Convert to USD first, then to target currency
    final priceInUSD = price / fromData.rateToUSD;
    return priceInUSD * toData.rateToUSD;
  }

  /// Format price with currency conversion
  /// Converts from product currency to user's preferred currency
  Future<String> formatPriceWithConversion(num price, String productCurrency) async {
    final userCurrency = await getUserCurrency();
    final convertedPrice = convertPrice(price, productCurrency, userCurrency);
    return formatPrice(convertedPrice, userCurrency);
  }

  /// Format price with currency symbol (no conversion)
  String formatPrice(num price, String currencyCode) {
    final data = currencies[currencyCode] ?? currencies['UGX']!;

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

  /// Clear cache and force refresh
  void clearCache() {
    _currencyCache.clear();
    _userCurrency = null;
  }
}
