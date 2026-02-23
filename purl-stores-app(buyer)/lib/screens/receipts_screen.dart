import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
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
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF1a1a1a)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Receipts',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1a1a1a),
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
            return const Center(child: CircularProgressIndicator(color: Color(0xFFfb2a0a)));
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
    
    // Format amount with k, m, b
    String formattedAmount;
    if (amount >= 1000000000) {
      formattedAmount = '${(amount / 1000000000).toStringAsFixed(2)}B';
    } else if (amount >= 1000000) {
      formattedAmount = '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      formattedAmount = '${(amount / 1000).toStringAsFixed(2)}K';
    } else {
      formattedAmount = amount.toStringAsFixed(0);
    }

    return GestureDetector(
      onTap: () => _showReceiptDetails(context, payment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFfb2a0a).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.receipt_2, color: Color(0xFFfb2a0a), size: 24),
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
                      color: const Color(0xFF1a1a1a),
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
                    color: const Color(0xFF1a1a1a),
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
    
    // Format amount with k, m, b
    String formattedAmount;
    if (amount >= 1000000000) {
      formattedAmount = '${(amount / 1000000000).toStringAsFixed(2)}B';
    } else if (amount >= 1000000) {
      formattedAmount = '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      formattedAmount = '${(amount / 1000).toStringAsFixed(2)}K';
    } else {
      formattedAmount = amount.toStringAsFixed(0);
    }
    
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
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFfb2a0a),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Transaction ${status == 'approved' ? 'Success' : status}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1a1a1a),
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
                                  color: Color(0xFFfb2a0a),
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
                                      color: const Color(0xFF1a1a1a),
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
                                const Icon(Iconsax.card, size: 16, color: Color(0xFF1a1a1a)),
                                const SizedBox(width: 4),
                                Text(
                                  paymentMethod,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1a1a1a),
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
                              color: const Color(0xFF1a1a1a),
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
                                  color: const Color(0xFF1a1a1a),
                                ),
                              ),
                              Text(
                                '$currency $formattedAmount',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1a1a1a),
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
                                foregroundColor: const Color(0xFF1a1a1a),
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
                                backgroundColor: const Color(0xFFb71000),
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
                color: const Color(0xFF1a1a1a),
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
  }) async {
    try {
      // Load logo
      final logoData = await rootBundle.load('assets/images/popstoreslogo.PNG');
      final logoBytes = logoData.buffer.asUint8List();
      final logo = pw.MemoryImage(logoBytes);

      // Create PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with logo
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(logo, width: 80, height: 80),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#fb2a0a'),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          date,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                
                // Success badge
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#4CAF50'),
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    'TRANSACTION SUCCESS',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),
                
                // Amount section
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F9F9F9'),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Amount Paid',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        amount,
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1a1a1a'),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                
                // Receipt details
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Receipt Details',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1a1a1a'),
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      _buildPdfDetailRow('Customer Name', buyerName),
                      _buildPdfDetailRow('Item Purchased', productName),
                      _buildPdfDetailRow('Payment Method', paymentMethod),
                      _buildPdfDetailRow('Transaction Date', date),
                      _buildPdfDetailRow('Transaction ID', transactionId),
                      pw.SizedBox(height: 16),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 16),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total Amount',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            amount,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#fb2a0a'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),
                
                // Footer
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Thank you for shopping with POP!',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#fb2a0a'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'For support, contact us through the app',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save and share PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/receipt_$transactionId.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Payment Receipt - $productName',
        text: 'Receipt for $productName - $amount',
      );
    } catch (e) {
      print('Error generating PDF: $e');
      // Fallback to text sharing
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

  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1a1a1a'),
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
