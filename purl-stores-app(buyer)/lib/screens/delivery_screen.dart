import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../services/currency_service.dart';
import 'help_support_screen.dart';

class DeliveryScreen extends StatefulWidget {
  final String orderId;
  final String status;
  final double total;
  final String productName;

  const DeliveryScreen({
    super.key,
    required this.orderId,
    required this.status,
    required this.total,
    required this.productName,
  });

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  final CurrencyService _currencyService = CurrencyService();

  int get _currentStep {
    switch (widget.status) {
      case 'confirmed':
      case 'pending':
        return 0;
      case 'preparing':
      case 'shipped':
        return 1;
      case 'picked':
      case 'picked_up':
      case 'in_transit':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 1;
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBeige,
        elevation: 0,
        leading: IconButton(icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Order ${widget.orderId}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.darkGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.headphone, size: 16, color: AppColors.darkGreen),
                  const SizedBox(width: 6),
                  Text('Support', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.darkGreen)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('orders')
            .where('orderNumber', isEqualTo: widget.orderId)
            .limit(1)
            .snapshots(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.warning_2, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading order', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('${orderSnapshot.error}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          if (!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.box, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('Order not found', style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Order #${widget.orderId}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          final orderData = orderSnapshot.data!.docs.first.data() as Map<String, dynamic>;
          final deliveryAddress = orderData['deliveryAddress'] as Map<String, dynamic>? ?? {};
          final items = (orderData['items'] as List<dynamic>?) ?? [];
          final total = (orderData['total'] ?? 0).toDouble();
          final deliveredAt = (orderData['deliveredAt'] as Timestamp?)?.toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(deliveredAt),
                const SizedBox(height: 24),
                _buildProgressTracker(),
                const SizedBox(height: 24),
                _buildLottieAnimation(),
                const SizedBox(height: 24),
                _buildDeliveryDetails(deliveryAddress),
                const SizedBox(height: 24),
                _buildOrderSummary(items, total),
                if (_currentStep == 2) ...[const SizedBox(height: 24), _buildDriverInfo()],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(DateTime? deliveredAt) {
    String title;
    String subtitle;
    switch (_currentStep) {
      case 0:
        title = 'Order Confirmed';
        subtitle = 'Your order is being processed';
        break;
      case 1:
        title = 'Preparing your order...';
        subtitle = 'Arriving soon';
        break;
      case 2:
        title = 'Your order has been picked';
        subtitle = 'Arriving soon';
        break;
      case 3:
        title = 'Order Delivered!';
        subtitle = deliveredAt != null 
            ? 'Delivered at ${DateFormat('h:mm a').format(deliveredAt)}'
            : 'Delivered successfully';
        break;
      default:
        title = 'Processing...';
        subtitle = 'Please wait';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildProgressTracker() {
    return Row(
      children: [
        _buildProgressStep(0, Iconsax.receipt_item, 'Confirmed'),
        _buildProgressLine(0),
        _buildProgressStep(1, Iconsax.box_time, 'Preparing'),
        _buildProgressLine(1),
        _buildProgressStep(2, Iconsax.truck_fast, 'Picked'),
        _buildProgressLine(2),
        _buildProgressStep(3, Iconsax.home_2, 'Delivered'),
      ],
    );
  }

  Widget _buildProgressStep(int step, IconData icon, String label) {
    final isCompleted = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Column(
      children: [
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) => Transform.scale(
            scale: isCurrent ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.darkGreen : Colors.white,
                shape: BoxShape.circle,
                boxShadow: isCurrent ? [BoxShadow(color: AppColors.darkGreen.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2)] : null,
              ),
              child: Icon(icon, size: 18, color: isCompleted ? Colors.white : AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400, color: isCompleted ? AppColors.darkGreen : AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildProgressLine(int afterStep) {
    final isCompleted = _currentStep > afterStep;
    return Expanded(child: Container(height: 3, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: isCompleted ? AppColors.darkGreen : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(2))));
  }

  Widget _buildLottieAnimation() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Lottie.asset('assets/animations/delivery splash.json', fit: BoxFit.contain, repeat: true, width: double.infinity, height: 200),
    );
  }

  Widget _buildDeliveryDetails(Map<String, dynamic> deliveryAddress) {
    final street = deliveryAddress['street'] ?? '';
    final city = deliveryAddress['city'] ?? '';
    final fullAddress = '$street${street.isNotEmpty && city.isNotEmpty ? ', ' : ''}$city';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery details', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildDetailRow(Iconsax.location, 'Address', fullAddress.isNotEmpty ? fullAddress : 'Delivery address'),
              const SizedBox(height: 12),
              _buildDetailRow(Iconsax.user, 'Type', 'Meet at door'),
              const SizedBox(height: 12),
              _buildDetailRow(Iconsax.box, 'Service', 'Standard'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.darkGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.darkGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(List<dynamic> items, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ...items.map((item) {
                final itemData = item as Map<String, dynamic>;
                final name = itemData['productName'] ?? itemData['name'] ?? 'Product';
                final price = (itemData['price'] ?? 0).toDouble();
                final currency = itemData['currency'] ?? 'KES';
                final quantity = itemData['quantity'] ?? 1;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Iconsax.box, size: 24, color: AppColors.darkGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                            Text('Qty: $quantity', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      FutureBuilder<String>(
                        future: _currencyService.formatPriceWithConversion(price, currency),
                        builder: (context, priceSnapshot) {
                          return Text(
                            priceSnapshot.data ?? _currencyService.formatPrice(price, currency),
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGreen),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
              Container(height: 1, color: AppColors.surfaceVariant),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total paid', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
                  FutureBuilder<String>(
                    future: _currencyService.formatPriceWithConversion(
                      total,
                      items.isNotEmpty ? (items.first as Map<String, dynamic>)['currency'] ?? 'KES' : 'KES',
                    ),
                    builder: (context, totalSnapshot) {
                      return Text(
                        totalSnapshot.data ?? _currencyService.formatPrice(total, 'KES'),
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGreen),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfo() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deliveries')
          .where('orderNumber', isEqualTo: widget.orderId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        String driverName = 'Delivery Person';
        String driverPhone = '';
        String vehicleInfo = 'Vehicle';
        String vehiclePlate = '';

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final deliveryData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          driverName = deliveryData['assignedCourierName'] ?? 'Delivery Person';
          driverPhone = deliveryData['assignedCourierPhone'] ?? '';

          final vName = deliveryData['vehicleName'];
          final vPlate = deliveryData['vehiclePlateNumber'];

          if (vName != null && vPlate != null) {
            vehicleInfo = vName;
            vehiclePlate = vPlate;
          } else if (vPlate != null) {
            vehicleInfo = vPlate;
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Driver', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: AppColors.darkGreen, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        driverName.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driverName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        if (vehiclePlate.isNotEmpty)
                          Text('$vehicleInfo • $vehiclePlate', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))
                        else
                          Text(vehicleInfo, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              if (driverPhone.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDriverAction(Iconsax.message, 'Message')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDriverAction(Iconsax.call, 'Call', driverPhone)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDriverAction(IconData icon, String label, [String? phone]) {
    return GestureDetector(
      onTap: phone != null && label == 'Call'
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Call $phone', style: GoogleFonts.poppins()),
                  backgroundColor: AppColors.darkGreen,
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.darkGreen),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
