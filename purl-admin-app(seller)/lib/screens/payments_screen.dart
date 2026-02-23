import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../services/payment_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final PaymentService _paymentService = PaymentService();

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'UGX':
        return 'USh ';
      case 'KES':
        return 'KSh ';
      case 'TZS':
        return 'TSh ';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '\$';
    }
  }

  String _formatAmount(double amount, String currency) {
    final symbol = _getCurrencySymbol(currency);
    
    if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(amount >= 10000 ? 0 : 1)}k';
    } else {
      return '$symbol${amount.toStringAsFixed(0)}';
    }
  }

  void _showPayoutSheet(double currentBalance, String currency) {
    final currencySymbol = _getCurrencySymbol(currency);
    final amountController = TextEditingController();
    final bankNameController = TextEditingController();
    final accountNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final mobileMoneyController = TextEditingController();
    final chipperTagController = TextEditingController();
    String payoutMethod = 'Bank Transfer';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600])),
                    ),
                    Text('Request Payout', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text) ?? 0;
                        if (amount > 0 && amount <= currentBalance) {
                          // Validate required fields based on method
                          Map<String, dynamic> details = {'currency': currency};
                          String? errorMessage;

                          if (payoutMethod == 'Bank Transfer') {
                            if (bankNameController.text.isEmpty || 
                                accountNameController.text.isEmpty || 
                                accountNumberController.text.isEmpty) {
                              errorMessage = 'Please fill in all bank details';
                            } else {
                              details['bankName'] = bankNameController.text;
                              details['accountName'] = accountNameController.text;
                              details['accountNumber'] = accountNumberController.text;
                            }
                          } else if (payoutMethod == 'Mobile Money') {
                            if (mobileMoneyController.text.isEmpty || accountNameController.text.isEmpty) {
                              errorMessage = 'Please enter mobile money number and account name';
                            } else {
                              details['mobileNumber'] = mobileMoneyController.text;
                              details['accountName'] = accountNameController.text;
                            }
                          } else if (payoutMethod == 'Chipper Cash') {
                            if (chipperTagController.text.isEmpty) {
                              errorMessage = 'Please enter Chipper Cash tag';
                            } else {
                              details['chipperTag'] = chipperTagController.text;
                            }
                          }

                          if (errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage, style: GoogleFonts.poppins()),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            await _paymentService.requestPayout(
                              amount: amount,
                              method: payoutMethod,
                              details: details,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Payout requested successfully', style: GoogleFonts.poppins()),
                                  backgroundColor: const Color(0xFFfb2a0a),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to request payout: $e', style: GoogleFonts.poppins()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else if (amount > currentBalance) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Amount exceeds available balance', style: GoogleFonts.poppins()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter a valid amount', style: GoogleFonts.poppins()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text('Request', style: GoogleFonts.poppins(color: const Color(0xFFfb2a0a), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: StatefulBuilder(
                    builder: (context, setState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Available Balance', style: GoogleFonts.poppins(color: Colors.grey[600])),
                              Text('$currencySymbol${currentBalance.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Amount', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            children: [
                              Text(currencySymbol, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '0.00',
                                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                                  ),
                                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Payout Method', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        ...['Bank Transfer', 'Mobile Money', 'Chipper Cash'].map((method) {
                          return GestureDetector(
                            onTap: () => setState(() => payoutMethod = method),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: payoutMethod == method ? const Color(0xFFfb2a0a) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    method == 'Bank Transfer'
                                        ? Iconsax.bank
                                        : method == 'Mobile Money'
                                            ? Iconsax.mobile
                                            : Iconsax.wallet,
                                    color: payoutMethod == method ? Colors.white : Colors.black,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    method,
                                    style: GoogleFonts.poppins(
                                      color: payoutMethod == method ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (payoutMethod == method)
                                    const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        // Conditional fields based on selected method
                        if (payoutMethod == 'Bank Transfer') ...[
                          Text('Bank Details', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          _buildTextField('Bank Name', 'e.g. Stanbic Bank', bankNameController),
                          const SizedBox(height: 12),
                          _buildTextField('Account Name', 'Full name on account', accountNameController),
                          const SizedBox(height: 12),
                          _buildTextField('Account Number', 'Enter account number', accountNumberController, keyboardType: TextInputType.number),
                        ] else if (payoutMethod == 'Mobile Money') ...[
                          Text('Mobile Money Details', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          _buildTextField('Account Name', 'Name registered on mobile money', accountNameController),
                          const SizedBox(height: 12),
                          _buildTextField('Mobile Number', '+256 XXX XXX XXX', mobileMoneyController, keyboardType: TextInputType.phone),
                        ] else if (payoutMethod == 'Chipper Cash') ...[
                          Text('Chipper Cash Details', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          _buildTextField('Chipper Tag', '@username', chipperTagController),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {TextInputType? keyboardType}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
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
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Payments', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<PaymentData>(
        stream: _paymentService.getPaymentDataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFfb2a0a)));
          }

          final paymentData = snapshot.data ?? PaymentData(balance: 0, transactions: [], currency: 'UGX');
          final balance = paymentData.balance;
          final transactions = paymentData.transactions;
          final currency = paymentData.currency;
          final currencySymbol = _getCurrencySymbol(currency);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFb71000),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available Balance', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(_formatAmount(balance, currency), style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _showPayoutSheet(balance, currency),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      ),
                      child: Text('Request Payout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Recent Transactions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No transactions yet',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                ...transactions.map((t) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            t.type == 'Sale'
                                ? Iconsax.arrow_down
                                : t.type == 'Commission'
                                    ? Iconsax.percentage_square
                                    : t.type == 'Payout'
                                        ? Iconsax.wallet_minus
                                        : Iconsax.arrow_up,
                            color: t.isPositive ? Colors.green : const Color(0xFFfb2a0a),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.type, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              Text(t.orderId ?? 'N/A', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              t.formattedAmount,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: t.isPositive ? Colors.green : const Color(0xFFfb2a0a),
                              ),
                            ),
                            Text(t.formattedDate, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
