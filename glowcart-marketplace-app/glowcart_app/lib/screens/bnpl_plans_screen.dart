import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class BnplPlansScreen extends StatefulWidget {
  const BnplPlansScreen({super.key});

  @override
  State<BnplPlansScreen> createState() => _BnplPlansScreenState();
}

class _BnplPlansScreenState extends State<BnplPlansScreen> {
  int _selectedTab = 1;

  final List<_BnplPlan> _plans = [
    _BnplPlan(id: '1', name: 'The iPhone 13 features...', amount: 620.00, installment: '5 of 6', date: '15 Apr', status: 'progress', payAmount: 155.00),
    _BnplPlan(id: '2', name: 'H&M Heavyweight Tshi...', amount: 128.00, installment: '6 of 12', date: '10 May', status: 'progress', payAmount: 155.00),
    _BnplPlan(id: '3', name: 'Apple Vision Pro', amount: 1230.00, installment: '6 of 12', date: '11 May', status: 'progress', payAmount: 155.00),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('My Plans', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Iconsax.setting_2, color: AppColors.textPrimary), onPressed: () {})],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          _buildTabs(),
          Expanded(child: _buildPlansList()),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Total to pay', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                const Spacer(),
                const Icon(Iconsax.info_circle, size: 18, color: Colors.white38),
              ],
            ),
            const SizedBox(height: 4),
            Text('\$678.33', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryStat('On progress', '\$399.67'),
                const SizedBox(width: 32),
                _buildSummaryStat('Overdue', '\$278.66'),
                const SizedBox(width: 32),
                _buildSummaryStat('Total Items', '4 Item'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  Widget _buildTabs() {
    final tabs = ['All', 'On Progress', 'Overdue', 'Completed'];
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkGreen : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(child: Text(tabs[index], style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.textSecondary))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlansList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: _plans.length,
      itemBuilder: (context, index) => _buildPlanCard(_plans[index]),
    );
  }

  Widget _buildPlanCard(_BnplPlan plan) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BnplPlanDetailScreen(plan: plan))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text(plan.date.split(' ')[0], style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text(plan.date.split(' ')[1], style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${plan.installment} installment', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${plan.amount.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.darkGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('On Progress', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.darkGreen)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text('Pay \$${plan.payAmount.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text('Details', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BnplPlan {
  final String id, name, installment, date, status;
  final double amount, payAmount;
  _BnplPlan({required this.id, required this.name, required this.amount, required this.installment, required this.date, required this.status, required this.payAmount});
}

class BnplPlanDetailScreen extends StatelessWidget {
  final _BnplPlan plan;
  const BnplPlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final payments = [
      _Payment(date: '15 Jan 2025', amount: 155.00, isPaid: true),
      _Payment(date: '15 Feb 2025', amount: 155.00, isPaid: true),
      _Payment(date: '15 Mar 2025', amount: 155.00, isPaid: true),
      _Payment(date: '15 Apr 2025', amount: 155.00, isPaid: false),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Plan Details', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Iconsax.share, color: AppColors.textPrimary), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remaining', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white70)),
                  Text('\$155.00', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildDetailStat('Order ID', '#1234567'),
                      const SizedBox(width: 24),
                      _buildDetailStat('Order Amount', '\$599.00'),
                      const SizedBox(width: 24),
                      _buildDetailStat('Total Payable', '\$620.00'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Iconsax.mobile, size: 28, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('iPhone 13 - features a sleek desi...', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Olive Green', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Next Installment: 15 April 2025', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.darkGreen)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Your Payment Schedule', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ...payments.map((p) => _buildPaymentRow(p, payments.indexOf(p) == payments.length - 1)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.document_download, size: 20, color: AppColors.darkGreen),
                    const SizedBox(width: 10),
                    Text('Download Receipt', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkGreen)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  Widget _buildPaymentRow(_Payment payment, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: payment.isPaid ? AppColors.darkGreen : AppColors.surfaceVariant, shape: BoxShape.circle),
              child: payment.isPaid ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            if (!isLast) Container(width: 2, height: 40, color: payment.isPaid ? AppColors.darkGreen : AppColors.surfaceVariant),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                Text(payment.date, style: GoogleFonts.poppins(fontSize: 14, color: payment.isPaid ? AppColors.textPrimary : AppColors.textSecondary)),
                const Spacer(),
                if (!payment.isPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(16)),
                    child: Text('Pay Early', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
                Text('\$${payment.amount.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Payment {
  final String date;
  final double amount;
  final bool isPaid;
  _Payment({required this.date, required this.amount, required this.isPaid});
}
