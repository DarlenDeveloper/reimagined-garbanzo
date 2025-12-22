import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class DiscountsScreen extends StatefulWidget {
  const DiscountsScreen({super.key});

  @override
  State<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends State<DiscountsScreen> {
  final List<Map<String, dynamic>> _discounts = [
    {'code': 'SUMMER20', 'discount': '20% off', 'usage': '45/100', 'status': 'Active', 'expires': '5 days left'},
    {'code': 'NEWUSER', 'discount': '\$50 off', 'usage': '12/50', 'status': 'Active', 'expires': '30 days left'},
    {'code': 'FLASH10', 'discount': '10% off', 'usage': '100/100', 'status': 'Expired', 'expires': 'Ended'},
  ];

  void _showCreateDiscountSheet() {
    final codeController = TextEditingController();
    final valueController = TextEditingController();
    final limitController = TextEditingController();
    String discountType = 'Percentage';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                  Text('Create Discount', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () {
                      if (codeController.text.isNotEmpty && valueController.text.isNotEmpty) {
                        final discountStr = discountType == 'Percentage' ? '${valueController.text}% off' : '\$${valueController.text} off';
                        setState(() {
                          _discounts.insert(0, {
                            'code': codeController.text.toUpperCase(),
                            'discount': discountStr,
                            'usage': '0/${limitController.text.isEmpty ? '∞' : limitController.text}',
                            'status': 'Active',
                            'expires': '30 days left',
                          });
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Discount created', style: GoogleFonts.poppins()), backgroundColor: Colors.black));
                      }
                    },
                    child: Text('Create', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildField('Discount Code', codeController, 'SUMMER20'),
                  const SizedBox(height: 16),
                  Text('Discount Type', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setTypeState) => Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setTypeState(() => discountType = 'Percentage'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: discountType == 'Percentage' ? Colors.black : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Text('Percentage', style: GoogleFonts.poppins(color: discountType == 'Percentage' ? Colors.white : Colors.black, fontWeight: FontWeight.w500))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setTypeState(() => discountType = 'Fixed'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: discountType == 'Fixed' ? Colors.black : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Text('Fixed Amount', style: GoogleFonts.poppins(color: discountType == 'Fixed' ? Colors.white : Colors.black, fontWeight: FontWeight.w500))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField('Value', valueController, discountType == 'Percentage' ? '10' : '50', keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildField('Usage Limit (optional)', limitController, '100', keyboardType: TextInputType.number),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: GoogleFonts.poppins(color: Colors.grey[400])),
            style: GoogleFonts.poppins(),
          ),
        ),
      ],
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
        title: Text('Discounts', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showCreateDiscountSheet, backgroundColor: Colors.black, child: const Icon(Iconsax.add, color: Colors.white)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _discounts.length,
        itemBuilder: (context, index) {
          final d = _discounts[index];
          final isActive = d['status'] == 'Active';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                      child: Text(d['code'], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: isActive ? Colors.green.withAlpha(25) : Colors.grey.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                      child: Text(d['status'], style: GoogleFonts.poppins(fontSize: 11, color: isActive ? Colors.green : Colors.grey, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(d['discount'], style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('Used: ${d['usage']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 4),
                Text(d['expires'], style: GoogleFonts.poppins(fontSize: 12, color: isActive ? Colors.orange : Colors.grey[500])),
              ],
            ),
          );
        },
      ),
    );
  }
}
