import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class BnplSubscriptionScreen extends StatefulWidget {
  const BnplSubscriptionScreen({super.key});

  @override
  State<BnplSubscriptionScreen> createState() => _BnplSubscriptionScreenState();
}

class _BnplSubscriptionScreenState extends State<BnplSubscriptionScreen> {
  int _selectedPlanIndex = 1;

  final List<_SubscriptionPlan> _plans = [
    _SubscriptionPlan(id: 'starter', name: 'Starter', monthlyFee: 4.99, maxQuota: 24.95, features: ['Up to \$24.95 BNPL limit', '5 installments per purchase', 'Basic support', 'Standard approval'], icon: Iconsax.star),
    _SubscriptionPlan(id: 'premium', name: 'Premium', monthlyFee: 14.99, maxQuota: 74.95, features: ['Up to \$74.95 BNPL limit', '5 installments per purchase', 'Priority support', 'Faster approval', 'Early access deals'], icon: Iconsax.crown, isPopular: true),
    _SubscriptionPlan(id: 'elite', name: 'Elite', monthlyFee: 29.99, maxQuota: 149.95, features: ['Up to \$149.95 BNPL limit', '5 installments per purchase', '24/7 VIP support', 'Instant approval', 'Exclusive deals', 'Unlock Scaling after 1 year'], icon: Iconsax.medal_star),
    _SubscriptionPlan(id: 'scaling', name: 'Scaling', monthlyFee: 49.99, maxQuota: 299.95, features: ['Up to \$299.95 BNPL limit', '5 installments per purchase', 'Dedicated account manager', 'Instant approval', 'All Elite benefits', 'Highest spending power'], icon: Iconsax.chart_2, requiresEliteYear: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(),
                    const SizedBox(height: 24),
                    _buildPlanCards(),
                    const SizedBox(height: 24),
                    _buildSelectedPlanDetails(),
                    const SizedBox(height: 16),
                    _buildCancellationWarning(),
                    const SizedBox(height: 24),
                    _buildFAQSection(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: const Icon(Iconsax.arrow_left, size: 20, color: Colors.black),
            ),
          ),
          const SizedBox(width: 12),
          Text('BNPL Plans', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Iconsax.crown, size: 14, color: Colors.black),
                const SizedBox(width: 4),
                Text('Premium', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Iconsax.wallet_3, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text('Buy Now, Pay Later', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Subscribe to unlock flexible payment options.\nAll purchases split into 5 easy installments.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70, height: 1.5)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeroStat('0%', 'Interest'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildHeroStat('5', 'Installments'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildHeroStat('Flexible', 'Terms'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildPlanCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Your Plan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _plans.length,
            itemBuilder: (context, index) => _buildPlanCard(_plans[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(_SubscriptionPlan plan, int index) {
    final isSelected = _selectedPlanIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 155,
        margin: EdgeInsets.only(right: 12, top: plan.isPopular ? 0 : 8, bottom: plan.isPopular ? 8 : 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            if (plan.isPopular)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.black, borderRadius: BorderRadius.circular(8)),
                  child: Text('Popular', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: isSelected ? Colors.black : Colors.white)),
                ),
              ),
            if (plan.requiresEliteYear)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.black, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.lock, size: 10, color: isSelected ? Colors.black : Colors.white),
                      const SizedBox(width: 2),
                      Text('1yr Elite', style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w600, color: isSelected ? Colors.black : Colors.white)),
                    ],
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(plan.icon, size: 26, color: isSelected ? Colors.white : Colors.black),
                const SizedBox(height: 10),
                Text(plan.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: '\$${plan.monthlyFee.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : Colors.black)),
                      TextSpan(text: '/mo', style: GoogleFonts.poppins(fontSize: 11, color: isSelected ? Colors.white70 : Colors.grey[600])),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Text('Max \$${plan.maxQuota.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.black)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPlanDetails() {
    final plan = _plans[_selectedPlanIndex];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                child: Icon(plan.icon, size: 22, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${plan.name} Plan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                  Text('What\'s included', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...plan.features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 12, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(feature, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCancellationWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.warning_2, size: 20, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cancellation Policy', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
                const SizedBox(height: 4),
                Text('If you cancel your subscription, any active BNPL plan will also be canceled and the full remaining amount will be deducted automatically.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      _FAQ('How does BNPL work?', 'All purchases are split into 5 equal installments. Pay over time with 0% interest.'),
      _FAQ('When am I charged?', 'Your monthly subscription is charged on the same day each month. Installments are due every 2 weeks.'),
      _FAQ('Can I upgrade my plan?', 'Yes! Upgrade anytime and your new quota takes effect immediately.'),
      _FAQ('What is Scaling?', 'Scaling is our highest tier, available only after 1 year of Elite membership. It offers the maximum BNPL limit of \$299.95.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frequently Asked', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 12),
        ...faqs.map((faq) => _buildFAQItem(faq)),
      ],
    );
  }

  Widget _buildFAQItem(_FAQ faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(faq.question, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
        iconColor: Colors.black,
        collapsedIconColor: Colors.grey[600],
        children: [Text(faq.answer, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], height: 1.5))],
      ),
    );
  }

  Widget _buildBottomBar() {
    final plan = _plans[_selectedPlanIndex];
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${plan.name} Plan', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              Text('\$${plan.monthlyFee.toStringAsFixed(2)}/month', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: plan.requiresEliteYear ? null : () => _showSubscribeDialog(plan),
              style: ElevatedButton.styleFrom(backgroundColor: plan.requiresEliteYear ? Colors.grey[400] : Colors.black, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text(plan.requiresEliteYear ? 'Requires 1yr Elite' : 'Subscribe Now', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscribeDialog(_SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                child: Icon(plan.icon, size: 32, color: Colors.black),
              ),
              const SizedBox(height: 16),
              Text('Subscribe to ${plan.name}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
              const SizedBox(height: 8),
              Text('You\'ll be charged \$${plan.monthlyFee.toStringAsFixed(2)} monthly.\nMax BNPL limit: \$${plan.maxQuota.toStringAsFixed(2)}\nAll purchases split into 5 installments.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], height: 1.5)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Iconsax.info_circle, size: 16, color: Colors.black),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Canceling subscription will auto-deduct remaining BNPL balance.', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showSuccessSnackbar(plan);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Confirm Subscription', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]))),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(_SubscriptionPlan plan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [const Icon(Iconsax.tick_circle, color: Colors.white, size: 20), const SizedBox(width: 10), Text('Subscribed to ${plan.name} plan!', style: GoogleFonts.poppins(fontSize: 13))]),
      backgroundColor: Colors.black,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

class _SubscriptionPlan {
  final String id, name;
  final double monthlyFee, maxQuota;
  final List<String> features;
  final IconData icon;
  final bool isPopular, requiresEliteYear;

  _SubscriptionPlan({required this.id, required this.name, required this.monthlyFee, required this.maxQuota, required this.features, required this.icon, this.isPopular = false, this.requiresEliteYear = false});
}

class _FAQ {
  final String question, answer;
  _FAQ(this.question, this.answer);
}
