import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/colors.dart';
import 'help_support_screen.dart';

class DeliveryScreen extends StatefulWidget {
  final String orderId;
  final String status;
  final double total;
  final String productName;

  const DeliveryScreen({
    super.key,
    this.orderId = 'ORD-2024-001',
    this.status = 'preparing',
    this.total = 154.97,
    this.productName = 'Smart Watch WH22-6',
  });

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  int get _currentStep {
    switch (widget.status) {
      case 'confirmed': return 0;
      case 'preparing': return 1;
      case 'picked':
      case 'in_transit': return 2;
      case 'delivered': return 3;
      default: return 1;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            _buildProgressTracker(),
            const SizedBox(height: 24),
            _buildLottieAnimation(),
            const SizedBox(height: 24),
            _buildDeliveryDetails(),
            const SizedBox(height: 24),
            _buildOrderSummary(),
            if (_currentStep == 2) ...[const SizedBox(height: 24), _buildDriverInfo()],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    String title;
    String subtitle = 'Arriving at 10:25 PM';
    switch (_currentStep) {
      case 0: title = 'Order Confirmed'; break;
      case 1: title = 'Preparing your order...'; break;
      case 2: title = 'Your order has been picked'; break;
      case 3: title = 'Order Delivered!'; subtitle = 'Delivered at 10:22 PM'; break;
      default: title = 'Processing...';
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
              width: 40, height: 40,
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
      height: 200, width: double.infinity,
      child: Stack(
        children: [
          Lottie.asset('assets/animations/delivery splash.json', fit: BoxFit.contain, repeat: true, width: double.infinity, height: 200),
          if (_currentStep == 2)
            Positioned(
              bottom: 16, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.clock, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Arriving in 4 mins', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(width: 12),
                      Text('10:25 PM', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetails() {
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
              _buildDetailRow(Iconsax.location, 'Address', '200 w 45th St, New York, NY 19980'),
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
          width: 36, height: 36,
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

  Widget _buildOrderSummary() {
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
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Iconsax.box, size: 24, color: AppColors.darkGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(widget.productName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                  Text('\$${widget.total.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGreen)),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: AppColors.surfaceVariant),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total paid', style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
                  Text('\$${(widget.total + 8).toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
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
          .where('orderId', isEqualTo: widget.orderId)
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
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: AppColors.darkGreen, shape: BoxShape.circle),
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
      onTap: phone != null && label == 'Call' ? () {
        // TODO: Implement phone call functionality
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call $phone', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      } : null,
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
