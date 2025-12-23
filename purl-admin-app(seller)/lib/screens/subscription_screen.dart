import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlan = 1;
  String _selectedCurrency = 'USD';

  final Map<String, _CurrencyData> _currencies = {
    'USD': _CurrencyData(symbol: '\$', name: 'US Dollar', proPrice: 9.99, businessPrice: 24.99),
    'EUR': _CurrencyData(symbol: '€', name: 'Euro', proPrice: 8.99, businessPrice: 22.99),
    'GBP': _CurrencyData(symbol: '£', name: 'British Pound', proPrice: 7.99, businessPrice: 19.99),
    'CAD': _CurrencyData(symbol: 'C\$', name: 'Canadian Dollar', proPrice: 12.99, businessPrice: 32.99),
    'JPY': _CurrencyData(symbol: '¥', name: 'Japanese Yen', proPrice: 1499, businessPrice: 3749),
    'SAR': _CurrencyData(symbol: 'SAR', name: 'Saudi Riyal', proPrice: 37.49, businessPrice: 93.74),
    'AED': _CurrencyData(symbol: 'AED', name: 'UAE Dirham', proPrice: 36.99, businessPrice: 91.99),
    'NGN': _CurrencyData(symbol: '₦', name: 'Nigerian Naira', proPrice: 14999, businessPrice: 37499),
    'GHS': _CurrencyData(symbol: 'GH₵', name: 'Ghanaian Cedi', proPrice: 149, businessPrice: 374),
    'KES': _CurrencyData(symbol: 'KSh', name: 'Kenyan Shilling', proPrice: 1499, businessPrice: 3749),
    'UGX': _CurrencyData(symbol: 'USh', name: 'Ugandan Shilling', proPrice: 36999, businessPrice: 92499),
    'TZS': _CurrencyData(symbol: 'TSh', name: 'Tanzanian Shilling', proPrice: 24999, businessPrice: 62499),
    'BIF': _CurrencyData(symbol: 'FBu', name: 'Burundian Franc', proPrice: 28499, businessPrice: 71249),
    'ZAR': _CurrencyData(symbol: 'R', name: 'South African Rand', proPrice: 179, businessPrice: 449),
  };

  List<_PlanData> get _plans {
    final currency = _currencies[_selectedCurrency]!;
    return [
      _PlanData(
        name: 'Starter',
        price: 'Free',
        period: 'forever',
        description: 'Perfect for getting started',
        features: ['Up to 10 products', 'Basic analytics', 'Standard support', '5% transaction fee'],
        isPopular: false,
      ),
      _PlanData(
        name: 'Pro',
        price: '${currency.symbol}${_formatPrice(currency.proPrice)}',
        period: '/month',
        description: 'Best for growing businesses',
        features: ['Unlimited products', 'Advanced analytics', 'Priority support', '2.5% transaction fee', 'AI Customer Care', 'Marketing tools', 'Custom domain'],
        isPopular: true,
      ),
      _PlanData(
        name: 'Business',
        price: '${currency.symbol}${_formatPrice(currency.businessPrice)}',
        period: '/month',
        description: 'For large scale operations',
        features: ['Everything in Pro', 'Multiple staff accounts', 'API access', '1% transaction fee', 'Dedicated manager', 'White-label options', 'Priority delivery'],
        isPopular: false,
      ),
    ];
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return price % 1 == 0 ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select Currency', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _currencies.length,
                itemBuilder: (context, index) {
                  final code = _currencies.keys.elementAt(index);
                  final data = _currencies[code]!;
                  final isSelected = code == _selectedCurrency;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCurrency = code);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(data.symbol, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.black)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(code, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.black)),
                                Text(data.name, style: GoogleFonts.poppins(fontSize: 12, color: isSelected ? Colors.grey[400] : Colors.grey[600])),
                              ],
                            ),
                          ),
                          if (isSelected) const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = _plans;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Iconsax.crown, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text('Choose Your Plan', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black)),
                  const SizedBox(height: 8),
                  Text('Select the plan that fits your business', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  // Currency Selector
                  GestureDetector(
                    onTap: _showCurrencyPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_currencies[_selectedCurrency]!.symbol, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          Text(_selectedCurrency, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 6),
                          Icon(Iconsax.arrow_down_1, size: 16, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: plans.length,
                itemBuilder: (context, index) => _buildPlanCard(plans[index], index),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/store-setup'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text(
                          _selectedPlan == 0 ? 'Start Free' : 'Subscribe & Continue',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.go('/store-setup'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                      child: Center(child: Text('Continue for Free', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 15, fontWeight: FontWeight.w500))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(_PlanData plan, int index) {
    final isSelected = _selectedPlan == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.black : Colors.grey[200]!, width: isSelected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(plan.name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : Colors.black)),
                          if (plan.isPopular) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.black, borderRadius: BorderRadius.circular(20)),
                              child: Text('Popular', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? Colors.black : Colors.white)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(plan.description, style: GoogleFonts.poppins(fontSize: 12, color: isSelected ? Colors.grey[400] : Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? Colors.white : Colors.transparent, border: Border.all(color: isSelected ? Colors.white : Colors.grey[300]!, width: 2)),
                  child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan.price, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : Colors.black)),
                if (plan.period != 'forever')
                  Padding(padding: const EdgeInsets.only(bottom: 4, left: 4), child: Text(plan.period, style: GoogleFonts.poppins(fontSize: 14, color: isSelected ? Colors.grey[400] : Colors.grey[600]))),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: isSelected ? Colors.grey[700] : Colors.grey[200]),
            const SizedBox(height: 12),
            ...plan.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Iconsax.tick_circle, size: 18, color: isSelected ? Colors.white : Colors.black),
                  const SizedBox(width: 10),
                  Expanded(child: Text(feature, style: GoogleFonts.poppins(fontSize: 13, color: isSelected ? Colors.grey[300] : Colors.grey[700]))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _PlanData {
  final String name, price, period, description;
  final List<String> features;
  final bool isPopular;
  _PlanData({required this.name, required this.price, required this.period, required this.description, required this.features, required this.isPopular});
}

class _CurrencyData {
  final String symbol, name;
  final double proPrice, businessPrice;
  _CurrencyData({required this.symbol, required this.name, required this.proPrice, required this.businessPrice});
}
