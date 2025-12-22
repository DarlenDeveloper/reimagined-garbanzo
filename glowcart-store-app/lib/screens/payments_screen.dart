import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  double _balance = 12450.00;
  final List<Map<String, dynamic>> _transactions = [
    {'type': 'Sale', 'amount': '+\$150.00', 'date': 'Today', 'orderId': '#GC-1234'},
    {'type': 'Commission', 'amount': '-\$4.50', 'date': 'Today', 'orderId': '#GC-1234'},
    {'type': 'Sale', 'amount': '+\$320.00', 'date': 'Yesterday', 'orderId': '#GC-1233'},
    {'type': 'Payout', 'amount': '-\$5,000.00', 'date': '2 days ago', 'orderId': 'Bank Transfer'},
  ];

  void _showPayoutSheet() {
    final amountController = TextEditingController();
    String payoutMethod = 'Bank Transfer';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600]))),
                  Text('Request Payout', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (amount > 0 && amount <= _balance) {
                        setState(() {
                          _balance -= amount;
                          _transactions.insert(0, {'type': 'Payout', 'amount': '-\$${amount.toStringAsFixed(2)}', 'date': 'Just now', 'orderId': payoutMethod});
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payout requested', style: GoogleFonts.poppins()), backgroundColor: Colors.black));
                      }
                    },
                    child: Text('Request', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Available Balance', style: GoogleFonts.poppins(color: Colors.grey[600])),
                        Text('\$${_balance.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Amount', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Text('\$', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(border: InputBorder.none, hintText: '0.00', hintStyle: GoogleFonts.poppins(color: Colors.grey[400])),
                            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Payout Method', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setMethodState) => Column(
                      children: ['Bank Transfer', 'Mobile Money', 'Chipper Cash'].map((method) => GestureDetector(
                        onTap: () => setMethodState(() => payoutMethod = method),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: payoutMethod == method ? Colors.black : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                method == 'Bank Transfer' ? Iconsax.bank : method == 'Mobile Money' ? Iconsax.mobile : Iconsax.wallet,
                                color: payoutMethod == method ? Colors.white : Colors.black,
                              ),
                              const SizedBox(width: 12),
                              Text(method, style: GoogleFonts.poppins(color: payoutMethod == method ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              if (payoutMethod == method) const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      )).toList(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Payments', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Balance', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14)),
                const SizedBox(height: 8),
                Text('\$${_balance.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showPayoutSheet,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  child: Text('Request Payout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Recent Transactions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._transactions.map((t) {
            final isPositive = t['amount'].startsWith('+');
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Icon(
                      t['type'] == 'Sale' ? Iconsax.arrow_down : t['type'] == 'Commission' ? Iconsax.percentage_square : Iconsax.arrow_up,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['type'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        Text(t['orderId'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(t['amount'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: isPositive ? Colors.green : Colors.red)),
                      Text(t['date'], style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
