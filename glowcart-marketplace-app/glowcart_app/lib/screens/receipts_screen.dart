import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/colors.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  final List<_Receipt> _receipts = [
    _Receipt(id: '1', name: 'John Doe', date: 'Sep 28, 2024 10:13 AM', description: 'Smart Watch Ultra', amount: 344.034, transactionId: '7412', status: 'success'),
    _Receipt(id: '2', name: 'John Doe', date: 'Sep 25, 2024 2:45 PM', description: 'Wireless Earbuds Pro', amount: 149.99, transactionId: '7398', status: 'success'),
    _Receipt(id: '3', name: 'John Doe', date: 'Sep 20, 2024 11:30 AM', description: 'Leather Crossbody Bag', amount: 89.99, transactionId: '7356', status: 'success'),
    _Receipt(id: '4', name: 'John Doe', date: 'Sep 15, 2024 4:20 PM', description: 'Running Shoes X1', amount: 159.99, transactionId: '7312', status: 'success'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Receipts', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receipts.length,
        itemBuilder: (context, index) => _buildReceiptCard(_receipts[index]),
      ),
    );
  }

  Widget _buildReceiptCard(_Receipt receipt) {
    return GestureDetector(
      onTap: () => _showReceiptDetails(receipt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: AppColors.darkGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Iconsax.receipt_2, color: AppColors.darkGreen, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(receipt.description, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(receipt.date, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${receipt.amount.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Success', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF22C55E))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptDetails(_Receipt receipt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReceiptDetailSheet(receipt: receipt),
    );
  }
}

class _ReceiptDetailSheet extends StatelessWidget {
  final _Receipt receipt;
  const _ReceiptDetailSheet({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.backgroundBeige,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Success Icon
                  Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(color: AppColors.darkGreen, shape: BoxShape.circle),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ...List.generate(12, (i) => Transform.rotate(
                          angle: i * 0.52,
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.darkGreen.withValues(alpha: 0.3), width: 2),
                            ),
                          ),
                        )),
                        Container(
                          width: 70, height: 70,
                          decoration: const BoxDecoration(color: AppColors.darkGreen, shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: Colors.white, size: 40),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Transaction Success', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 32),
                  // Amount Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.darkGreen,
                          child: Text('JD', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Amount', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                            Text('\$${receipt.amount.toStringAsFixed(3)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              const Icon(Iconsax.card, size: 16, color: AppColors.textPrimary),
                              const SizedBox(width: 6),
                              Text('Card', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Receipt Details
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Receipt Details', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 16),
                        _buildDetailRow('Name', receipt.name),
                        _buildDetailRow('Transaction Date', receipt.date),
                        _buildDetailRow('Item Purchased', receipt.description),
                        _buildDetailRow('Amount', '\$${receipt.amount.toStringAsFixed(3)}'),
                        _buildDetailRow('Transaction ID', '************${receipt.transactionId}'),
                        const SizedBox(height: 12),
                        Container(height: 1, color: AppColors.surfaceVariant),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text('\$${(receipt.amount + 2).toStringAsFixed(3)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Iconsax.document_download, size: 20, color: AppColors.textPrimary),
                                const SizedBox(width: 8),
                                Text('Export', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(14)),
                            child: Center(child: Text('OK', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _Receipt {
  final String id, name, date, description, transactionId, status;
  final double amount;
  _Receipt({required this.id, required this.name, required this.date, required this.description, required this.amount, required this.transactionId, required this.status});
}
