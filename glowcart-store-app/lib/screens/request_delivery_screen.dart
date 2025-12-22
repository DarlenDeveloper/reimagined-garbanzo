import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class RequestDeliveryScreen extends StatefulWidget {
  final String? orderId;
  final String? customerName;
  final String? deliveryAddress;
  final String? orderAmount;
  final VoidCallback? onDeliveryRequested;
  
  const RequestDeliveryScreen({
    super.key, 
    this.orderId,
    this.customerName,
    this.deliveryAddress,
    this.orderAmount,
    this.onDeliveryRequested,
  });

  @override
  State<RequestDeliveryScreen> createState() => _RequestDeliveryScreenState();
}

class _RequestDeliveryScreenState extends State<RequestDeliveryScreen> {
  int _currentStep = 0;
  String _deliveryType = 'standard';
  String _packageSize = 'small';
  bool _isFragile = false;
  bool _requiresSignature = false;
  double? _estimatedPrice;
  String? _estimatedTime;
  bool _isLoadingQuote = false;

  final _pickupAddressController = TextEditingController(text: 'GlowCart Store, 123 Commerce St');
  final _pickupContactController = TextEditingController(text: '+1 234 567 8900');
  final _pickupNotesController = TextEditingController();
  late TextEditingController _dropoffAddressController;
  final _dropoffContactController = TextEditingController();
  final _dropoffNotesController = TextEditingController();
  late TextEditingController _customerNameController;

  @override
  void initState() {
    super.initState();
    _dropoffAddressController = TextEditingController(text: widget.deliveryAddress ?? '');
    _customerNameController = TextEditingController(text: widget.customerName ?? '');
  }

  void _getQuote() {
    if (_dropoffAddressController.text.isEmpty) return;
    setState(() => _isLoadingQuote = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoadingQuote = false;
        _estimatedPrice = _deliveryType == 'express' ? 35.00 : _deliveryType == 'scheduled' ? 20.00 : 25.00;
        _estimatedTime = _deliveryType == 'express' ? '30-45 min' : _deliveryType == 'scheduled' ? 'As scheduled' : '45-60 min';
      });
    });
  }

  void _requestDelivery() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.withAlpha(25), shape: BoxShape.circle),
              child: const Icon(Iconsax.tick_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 24),
            Text('Delivery Requested!', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(widget.orderId != null ? 'Finding a driver for order ${widget.orderId}' : 'Finding a driver for your delivery', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey[600])),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDeliveryRequested?.call();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Done', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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
        title: Text(widget.orderId != null ? 'Deliver ${widget.orderId}' : 'Request Delivery', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Order Info Banner (if from order)
          if (widget.orderId != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Iconsax.box, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order ${widget.orderId}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('${widget.customerName} • ${widget.orderAmount}', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _currentStep == 0 ? _buildPickupStep() : _currentStep == 1 ? _buildDropoffStep() : _currentStep == 2 ? _buildPackageStep() : _buildConfirmStep(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _stepDot(0, 'Pickup'),
          _stepLine(0),
          _stepDot(1, 'Dropoff'),
          _stepLine(1),
          _stepDot(2, 'Package'),
          _stepLine(2),
          _stepDot(3, 'Confirm'),
        ],
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: isActive ? Colors.black : Colors.grey[300], shape: BoxShape.circle),
          child: Center(child: isActive && _currentStep > step ? const Icon(Iconsax.tick_circle, color: Colors.white, size: 16) : Text('${step + 1}', style: GoogleFonts.poppins(color: isActive ? Colors.white : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600))),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: isActive ? Colors.black : Colors.grey[500])),
      ],
    );
  }

  Widget _stepLine(int afterStep) {
    return Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 16), color: _currentStep > afterStep ? Colors.black : Colors.grey[300]));
  }

  Widget _buildPickupStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Pickup Location', Iconsax.location),
        const SizedBox(height: 16),
        _buildTextField('Pickup Address', _pickupAddressController, Iconsax.location),
        const SizedBox(height: 12),
        _buildTextField('Contact Number', _pickupContactController, Iconsax.call, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _buildTextField('Pickup Notes (optional)', _pickupNotesController, Iconsax.note, hint: 'e.g., Ring doorbell, ask for John'),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Icon(Iconsax.shop, size: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Store Pickup', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    Text('Driver will pick up from your store', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              const Icon(Iconsax.tick_circle, color: Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropoffStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Delivery Location', Iconsax.location_tick),
        const SizedBox(height: 16),
        _buildTextField('Customer Name', _customerNameController, Iconsax.user),
        const SizedBox(height: 12),
        _buildTextField('Delivery Address', _dropoffAddressController, Iconsax.location_tick, hint: 'Enter full address'),
        const SizedBox(height: 12),
        _buildTextField('Customer Phone', _dropoffContactController, Iconsax.call, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _buildTextField('Delivery Notes (optional)', _dropoffNotesController, Iconsax.note, hint: 'e.g., Leave at door, call on arrival'),
        const SizedBox(height: 24),
        Text('Delivery Type', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _deliveryTypeOption('standard', 'Standard', '45-60 min', '\$25.00', Iconsax.truck),
        _deliveryTypeOption('express', 'Express', '30-45 min', '\$35.00', Iconsax.flash_1),
        _deliveryTypeOption('scheduled', 'Scheduled', 'Pick a time', '\$20.00', Iconsax.calendar),
      ],
    );
  }

  Widget _deliveryTypeOption(String value, String title, String time, String price, IconData icon) {
    final isSelected = _deliveryType == value;
    return GestureDetector(
      onTap: () => setState(() => _deliveryType = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.black)),
                  Text(time, style: GoogleFonts.poppins(fontSize: 12, color: isSelected ? Colors.grey[400] : Colors.grey[600])),
                ],
              ),
            ),
            Text(price, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: isSelected ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Package Details', Iconsax.box),
        const SizedBox(height: 16),
        Text('Package Size', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            _packageSizeOption('small', 'Small', 'Fits in a bag'),
            const SizedBox(width: 12),
            _packageSizeOption('medium', 'Medium', 'Shoebox size'),
            const SizedBox(width: 12),
            _packageSizeOption('large', 'Large', 'Needs both hands'),
          ],
        ),
        const SizedBox(height: 24),
        Text('Special Handling', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _toggleOption('Fragile Item', 'Handle with extra care', _isFragile, (v) => setState(() => _isFragile = v)),
        _toggleOption('Signature Required', 'Customer must sign on delivery', _requiresSignature, (v) => setState(() => _requiresSignature = v)),
      ],
    );
  }

  Widget _packageSizeOption(String value, String title, String desc) {
    final isSelected = _packageSize == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _packageSize = value),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(value == 'small' ? Iconsax.box_1 : value == 'medium' ? Iconsax.box : Iconsax.box_2, color: isSelected ? Colors.white : Colors.black, size: 28),
              const SizedBox(height: 8),
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.black, fontSize: 13)),
              Text(desc, style: GoogleFonts.poppins(fontSize: 10, color: isSelected ? Colors.grey[400] : Colors.grey[600]), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleOption(String title, String desc, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Colors.black.withAlpha(100),
            thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? Colors.black : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep() {
    if (_estimatedPrice == null && !_isLoadingQuote) {
      _getQuote();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.truck_fast, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text('GlowCart Delivery', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                child: Text('API', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _summarySection('Pickup', _pickupAddressController.text, Iconsax.location),
        _summarySection('Dropoff', '${_customerNameController.text}\n${_dropoffAddressController.text}', Iconsax.location_tick),
        _summarySection('Package', '${_packageSize.toUpperCase()} • ${_isFragile ? "Fragile" : "Standard"}${_requiresSignature ? " • Signature" : ""}', Iconsax.box),
        _summarySection('Delivery', '${_deliveryType == 'express' ? 'Express' : _deliveryType == 'scheduled' ? 'Scheduled' : 'Standard'} Delivery', Iconsax.truck_fast),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
          child: _isLoadingQuote
              ? Center(child: Column(children: [const CircularProgressIndicator(color: Colors.black), const SizedBox(height: 12), Text('Getting quote...', style: GoogleFonts.poppins(color: Colors.grey[600]))]))
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Estimated Time', style: GoogleFonts.poppins(color: Colors.grey[600])),
                        Text(_estimatedTime ?? '—', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery Fee', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                        Text('\$${_estimatedPrice?.toStringAsFixed(2) ?? '—'}', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _summarySection(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20)),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {String? hint, TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
          icon: Icon(icon, color: Colors.grey[600]),
        ),
        style: GoogleFonts.poppins(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.black), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Back', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep < 3 ? () => setState(() => _currentStep++) : _requestDelivery,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(_currentStep < 3 ? 'Continue' : 'Request Delivery', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
