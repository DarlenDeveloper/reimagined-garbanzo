import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ShippingScreen extends StatefulWidget {
  const ShippingScreen({super.key});

  @override
  State<ShippingScreen> createState() => _ShippingScreenState();
}

class _ShippingScreenState extends State<ShippingScreen> {
  final List<Map<String, dynamic>> _shipments = [
    {'trackingNo': 'SKY-123456', 'orderId': '#GC-1234', 'status': 'In Transit', 'carrier': 'Skynet', 'weight': '0.5kg', 'destination': 'Accra'},
    {'trackingNo': 'SKY-123455', 'orderId': '#GC-1233', 'status': 'Delivered', 'carrier': 'Skynet', 'weight': '1.2kg', 'destination': 'Kumasi'},
    {'trackingNo': 'SKY-123454', 'orderId': '#GC-1232', 'status': 'Processing', 'carrier': 'Skynet', 'weight': '0.3kg', 'destination': 'Tema'},
  ];

  void _showCreateShipmentSheet() {
    final orderIdController = TextEditingController();
    final weightController = TextEditingController();
    final destinationController = TextEditingController();
    String selectedCarrier = 'Skynet';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
                  Text('Create Shipment', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () {
                      if (orderIdController.text.isNotEmpty) {
                        setState(() {
                          _shipments.insert(0, {
                            'trackingNo': 'SKY-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            'orderId': orderIdController.text,
                            'status': 'Processing',
                            'carrier': selectedCarrier,
                            'weight': '${weightController.text}kg',
                            'destination': destinationController.text,
                          });
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shipment created', style: GoogleFonts.poppins()), backgroundColor: Colors.black));
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
                  _buildField('Order ID', orderIdController, '#GC-0000'),
                  const SizedBox(height: 16),
                  Text('Carrier', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setDropdownState) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCarrier,
                          isExpanded: true,
                          style: GoogleFonts.poppins(color: Colors.black),
                          items: ['Skynet', 'DHL', 'FedEx', 'UPS'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setDropdownState(() => selectedCarrier = v!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField('Weight (kg)', weightController, '0.0', keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildField('Destination', destinationController, 'City'),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Iconsax.info_circle, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Shipping label will be generated automatically', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]))),
                      ],
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

  void _showShipmentDetails(Map<String, dynamic> shipment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(shipment['trackingNo'], style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
                _statusBadge(shipment['status']),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Order', shipment['orderId']),
            _detailRow('Carrier', shipment['carrier']),
            _detailRow('Weight', shipment['weight']),
            _detailRow('Destination', shipment['destination']),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.document_download, size: 18),
                    label: Text('Download Label', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.location, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.grey[600])),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'Delivered' ? Colors.green : status == 'In Transit' ? Colors.blue : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
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
        title: Text('Shipping', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateShipmentSheet,
        backgroundColor: Colors.black,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _shipments.length,
        itemBuilder: (context, index) {
          final shipment = _shipments[index];
          final color = shipment['status'] == 'Delivered' ? Colors.green : shipment['status'] == 'In Transit' ? Colors.blue : Colors.orange;
          return GestureDetector(
            onTap: () => _showShipmentDetails(shipment),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(shipment['trackingNo'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                        child: Text(shipment['status'], style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Order: ${shipment['orderId']} • ${shipment['carrier']} • ${shipment['destination']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
