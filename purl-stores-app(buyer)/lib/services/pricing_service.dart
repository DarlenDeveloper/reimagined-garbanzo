/// Simple pricing service to calculate markup
class PricingService {
  /// Calculate final buyer price with markup
  static double calculateFinalPrice(double sellerPrice) {
    final markup = _getMarkupPercentage(sellerPrice);
    return sellerPrice + (sellerPrice * markup);
  }

  /// Get markup percentage based on price tier
  static double _getMarkupPercentage(double price) {
    if (price >= 500001) return 0.03;      // 3%
    if (price >= 260001) return 0.04;      // 4%
    if (price >= 125001) return 0.06;      // 6%
    if (price >= 100001) return 0.09;      // 9%
    if (price >= 75001) return 0.11;       // 11%
    if (price >= 50001) return 0.14;       // 14%
    if (price >= 25000) return 0.168;      // 16.8%
    return 0.168; // Default 16.8% for prices below 25,000
  }

  /// Get seller's net amount (what they receive)
  static double getSellerAmount(double sellerPrice) {
    return sellerPrice; // Seller gets their full listed price
  }

  /// Get platform markup amount
  static double getMarkupAmount(double sellerPrice) {
    return calculateFinalPrice(sellerPrice) - sellerPrice;
  }
}
