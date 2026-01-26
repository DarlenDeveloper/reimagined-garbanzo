import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'store_profile_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _flashOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Parse deep link: purl://stores/{storeSlug}
      if (code.startsWith('purl://stores/')) {
        final storeSlug = code.replaceFirst('purl://stores/', '');
        await _navigateToStore(storeSlug);
      } else {
        _showError('Invalid QR code. Please scan a Purl store QR code.');
      }
    } catch (e) {
      _showError('Failed to process QR code');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _navigateToStore(String storeSlug) async {
    try {
      // First try to find by slug
      var querySnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .where('slug', isEqualTo: storeSlug)
          .limit(1)
          .get();

      // If not found by slug, try using slug as store ID directly
      if (querySnapshot.docs.isEmpty) {
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeSlug)
            .get();
        
        if (storeDoc.exists) {
          final storeData = storeDoc.data()!;
          final storeId = storeDoc.id;
          final storeName = storeData['name'] as String? ?? 'Store';

          if (mounted) {
            await _controller.stop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => StoreProfileScreen(
                  storeId: storeId,
                  storeName: storeName,
                  storeAvatar: storeName.isNotEmpty ? storeName[0] : 'S',
                ),
              ),
            );
          }
          return;
        }
        
        _showError('Store not found');
        return;
      }

      final storeDoc = querySnapshot.docs.first;
      final storeData = storeDoc.data();
      final storeId = storeDoc.id;
      final storeName = storeData['name'] as String? ?? 'Store';

      if (mounted) {
        await _controller.stop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StoreProfileScreen(
              storeId: storeId,
              storeName: storeName,
              storeAvatar: storeName.isNotEmpty ? storeName[0] : 'S',
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to load store: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleFlash() {
    setState(() => _flashOn = !_flashOn);
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          
          // Overlay with cutout
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),
          
          // Top bar
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleFlash,
                        icon: Icon(
                          _flashOn ? Iconsax.flash_15 : Iconsax.flash_1,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      if (_isProcessing)
                        const CircularProgressIndicator(color: Colors.white)
                      else ...[
                        const Icon(Iconsax.scan_barcode, color: Colors.white, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          'Scan Store QR Code',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Point your camera at a store QR code',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final cutoutSize = size.width * 0.7;
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutoutSize,
      height: cutoutSize,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final bracketLength = 30.0;
    
    // Top-left
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.top + bracketLength),
      Offset(cutoutRect.left, cutoutRect.top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.top),
      Offset(cutoutRect.left + bracketLength, cutoutRect.top),
      bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(cutoutRect.right - bracketLength, cutoutRect.top),
      Offset(cutoutRect.right, cutoutRect.top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.top),
      Offset(cutoutRect.right, cutoutRect.top + bracketLength),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.bottom - bracketLength),
      Offset(cutoutRect.left, cutoutRect.bottom),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.bottom),
      Offset(cutoutRect.left + bracketLength, cutoutRect.bottom),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(cutoutRect.right - bracketLength, cutoutRect.bottom),
      Offset(cutoutRect.right, cutoutRect.bottom),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.bottom - bracketLength),
      Offset(cutoutRect.right, cutoutRect.bottom),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
