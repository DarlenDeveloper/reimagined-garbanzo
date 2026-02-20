import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/colors.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left, color: AppColors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Receipts',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: Text('Please login to view receipts')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Receipts',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'approved')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.black));
          }

          final payments = snapshot.data?.docs ?? [];

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.receipt_2, size: 64, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text(
                    'No receipts yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your payment receipts will appear here',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index].data() as Map<String, dynamic>;
              return _buildReceiptCard(context, payment);
            },
          );
        },
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, Map<String, dynamic> payment) {
    final amount = (payment['amount'] ?? 0).toDouble();
    final currency = payment['currency'] ?? 'UGX';
    final status = payment['status'] ?? 'pending';
    final createdAt = (payment['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    // Get product name from items array
    String productName = 'Order';
    final items = payment['items'] as List<dynamic>?;
    if (items != null && items.isNotEmpty) {
      final firstItem = items[0] as Map<String, dynamic>;
      productName = firstItem['name'] ?? 'Order';
    }
    
    // Format amount without decimals for UGX
    final formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return GestureDetector(
      onTap: () => _showReceiptDetails(context, payment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.receipt_2, color: AppColors.black, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy h:mm a').format(createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency $formattedAmount',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Success',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptDetails(BuildContext context, Map<String, dynamic> payment) async {
    final amount = (payment['amount'] ?? 0).toDouble();
    final currency = payment['currency'] ?? 'UGX';
    final paymentMethod = payment['paymentMethod'] ?? 'Card';
    final status = payment['status'] ?? 'pending';
    final createdAt = (payment['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    // Handle transactionId as either int or string
    final transactionIdRaw = payment['transactionId'] ?? payment['txRef'];
    final transactionId = transactionIdRaw?.toString() ?? 'N/A';
    
    // Get buyer first name from users collection
    String buyerName = 'Customer';
    final userId = payment['userId'] ?? payment['buyerId'];
    if (userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId.toString())
            .get();
        
        if (userDoc.exists) {
          buyerName = userDoc.data()?['firstName']?.toString() ?? 
                      userDoc.data()?['name']?.toString() ?? 
                      'Customer';
        }
      } catch (e) {
        print('Error fetching user name: $e');
      }
    }
    
    // Get product name from items
    String productName = 'Order';
    final items = payment['items'] as List<dynamic>?;
    if (items != null && items.isNotEmpty) {
      final firstItem = items[0] as Map<String, dynamic>;
      productName = firstItem['name']?.toString() ?? 'Order';
    }
    
    // Format amount without decimals for UGX
    final formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    // Mask transaction ID
    String maskedTxId = transactionId;
    if (transactionId != 'N/A' && transactionId.length > 4) {
      maskedTxId = '${'*' * (transactionId.length - 4)}${transactionId.substring(transactionId.length - 4)}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Success Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 50),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Transaction ${status == 'approved' ? 'Success' : status}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Amount Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: AppColors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    buyerName.isNotEmpty ? buyerName[0].toUpperCase() : 'J',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Amount',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                  Text(
                                    '$currency $formattedAmount',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Iconsax.card, size: 16, color: AppColors.black),
                                const SizedBox(width: 4),
                                Text(
                                  paymentMethod,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Receipt Details
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Receipt Details',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Name', buyerName),
                          _buildDetailRow('Transaction Date', DateFormat('MMM dd, yyyy h:mm a').format(createdAt)),
                          _buildDetailRow('Item Purchased', productName),
                          _buildDetailRow('Amount', '$currency $formattedAmount'),
                          _buildDetailRow('Transaction ID', maskedTxId),
                          const SizedBox(height: 16),
                          Container(height: 1, color: AppColors.grey300),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                              Text(
                                '$currency $formattedAmount',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black,
                                ),
                              ),
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
                          child: SizedBox(
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _exportReceipt(
                                  buyerName: buyerName,
                                  productName: productName,
                                  amount: '$currency $formattedAmount',
                                  transactionId: maskedTxId,
                                  date: DateFormat('MMM dd, yyyy h:mm a').format(createdAt),
                                  paymentMethod: paymentMethod,
                                );
                              },
                              icon: const Icon(Iconsax.export, size: 20),
                              label: Text(
                                'Export',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.black,
                                side: const BorderSide(color: AppColors.grey300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(27),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.black,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(27),
                                ),
                              ),
                              child: Text(
                                'OK',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.grey600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _exportReceipt({
    required String buyerName,
    required String productName,
    required String amount,
    required String transactionId,
    required String date,
    required String paymentMethod,
  }) {
    final receiptText = '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        PAYMENT RECEIPT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Customer: $buyerName
Item: $productName
Payment Method: $paymentMethod
Date: $date

Amount: $amount
Transaction ID: $transactionId

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Thank you for your purchase!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';

    Share.share(
      receiptText,
      subject: 'Payment Receipt - $productName',
    );
  }
}
