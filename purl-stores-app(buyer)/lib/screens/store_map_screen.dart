import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import '../theme/colors.dart';
import '../services/location_service.dart';
import '../services/stores_service.dart';
import '../services/messages_service.dart';
import 'store_profile_screen.dart';
import 'store_chat_screen.dart';

class StoreMapScreen extends StatefulWidget {
  const StoreMapScreen({super.key});

  @override
  State<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends State<StoreMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final LocationService _locationService = LocationService();
  final StoresService _storesService = StoresService();
  final MessagesService _messagesService = MessagesService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  GoogleMapController? _mapController;
  List<Map<String, dynamic>> _nearbyStores = [];
  Map<String, dynamic>? _selectedStore;
  bool _isLoading = true;
  Position? _userPosition;
  Map<String, BitmapDescriptor> _customIcons = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadNearbyStores();
  }

  Future<void> _loadNearbyStores() async {
    setState(() => _isLoading = true);
    
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permission denied', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      setState(() => _userPosition = position);
      
      final stores = await _storesService.getNearbyStores(
        position.latitude,
        position.longitude,
        radiusKm: 10,
      );
      
      // Create custom icons for each store
      await _createCustomMarkerIcons(stores);
      
      setState(() {
        _nearbyStores = stores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stores: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createCustomMarkerIcons(List<Map<String, dynamic>> stores) async {
    for (final store in stores) {
      final storeId = store['id'] as String;
      final logoUrl = store['logoUrl'] as String?;
      
      BitmapDescriptor customIcon;
      if (logoUrl != null && logoUrl.isNotEmpty) {
        customIcon = await _createLogoMarkerIcon(logoUrl, false);
      } else {
        final category = store['category'] as String;
        final icon = _getCategoryIcon(category);
        customIcon = await _createMarkerIcon(icon, false);
      }
      
      _customIcons[storeId] = customIcon;
    }
  }

  Future<BitmapDescriptor> _createLogoMarkerIcon(String logoUrl, bool isSelected) async {
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final size = 120.0; // Increased from 80 to 120
      
      // Draw circle background
      final paint = Paint()
        ..color = isSelected ? Colors.black : Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2,
        paint,
      );
      
      // Draw border
      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4; // Increased from 3 to 4
      
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2 - 2,
        borderPaint,
      );
      
      // Load and draw logo image
      try {
        final imageProvider = NetworkImage(logoUrl);
        final imageStream = imageProvider.resolve(const ImageConfiguration());
        final completer = Completer<ui.Image>();
        
        imageStream.addListener(ImageStreamListener((ImageInfo info, bool _) {
          completer.complete(info.image);
        }));
        
        final image = await completer.future.timeout(const Duration(seconds: 3));
        
        // Draw circular clipped logo
        final logoSize = size - 24; // Increased padding
        final logoRect = Rect.fromLTWH(12, 12, logoSize, logoSize);
        
        canvas.save();
        canvas.clipPath(Path()..addOval(logoRect));
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          logoRect,
          Paint(),
        );
        canvas.restore();
      } catch (e) {
        // If logo fails to load, draw a shop icon instead
        final textPainter = TextPainter(textDirection: TextDirection.ltr);
        textPainter.text = TextSpan(
          text: String.fromCharCode(Iconsax.shop.codePoint),
          style: TextStyle(
            fontSize: 48, // Increased from 36 to 48
            fontFamily: Iconsax.shop.fontFamily,
            color: isSelected ? Colors.white : Colors.black,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            (size - textPainter.width) / 2,
            (size - textPainter.height) / 2,
          ),
        );
      }
      
      final picture = pictureRecorder.endRecording();
      final finalImage = await picture.toImage(size.toInt(), size.toInt());
      final bytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      
      return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    } catch (e) {
      // Fallback to icon-based marker
      return _createMarkerIcon(Iconsax.shop, isSelected);
    }
  }

  Future<BitmapDescriptor> _createMarkerIcon(IconData iconData, bool isSelected) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = 120.0; // Increased from 80 to 120
    
    // Draw circle background
    final paint = Paint()
      ..color = isSelected ? Colors.black : Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );
    
    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4; // Increased from 3 to 4
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 2,
      borderPaint,
    );
    
    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 52, // Increased from 36 to 52
        fontFamily: iconData.fontFamily,
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.darkGreen),
                  const SizedBox(height: 16),
                  Text(
                    'Loading nearby stores...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          _buildMapArea(),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _buildStoreList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildFloatingBackButton(),
              ],
            ),
    );
  }

  Widget _buildFloatingBackButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.search_normal, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    'Search stores nearby',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (_mapController != null && _userPosition != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_userPosition!.latitude, _userPosition!.longitude),
                    14,
                  ),
                );
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.gps, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    if (_userPosition == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.darkGreen),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(_userPosition!.latitude, _userPosition!.longitude),
            zoom: 14,
          ),
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _nearbyStores.map((store) {
            final storeId = store['id'] as String;
            final isSelected = _selectedStore?['id'] == storeId;
            
            return Marker(
              markerId: MarkerId(storeId),
              position: LatLng(store['latitude'], store['longitude']),
              icon: _customIcons[storeId] ?? BitmapDescriptor.defaultMarker,
              onTap: () async {
                setState(() => _selectedStore = store);
                // Recreate icon for selected state
                final logoUrl = store['logoUrl'] as String?;
                BitmapDescriptor selectedIcon;
                if (logoUrl != null && logoUrl.isNotEmpty) {
                  selectedIcon = await _createLogoMarkerIcon(logoUrl, true);
                } else {
                  final icon = _getCategoryIcon(store['category']);
                  selectedIcon = await _createMarkerIcon(icon, true);
                }
                setState(() => _customIcons[storeId] = selectedIcon);
              },
            );
          }).toSet(),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          onTap: (LatLng position) async {
            // Deselect store and reset all icons to unselected state
            if (_selectedStore != null) {
              final previousStoreId = _selectedStore!['id'] as String;
              final previousStore = _nearbyStores.firstWhere((s) => s['id'] == previousStoreId);
              final logoUrl = previousStore['logoUrl'] as String?;
              BitmapDescriptor unselectedIcon;
              if (logoUrl != null && logoUrl.isNotEmpty) {
                unselectedIcon = await _createLogoMarkerIcon(logoUrl, false);
              } else {
                final icon = _getCategoryIcon(previousStore['category']);
                unselectedIcon = await _createMarkerIcon(icon, false);
              }
              setState(() {
                _customIcons[previousStoreId] = unselectedIcon;
                _selectedStore = null;
              });
            }
          },
        ),
        if (_nearbyStores.isEmpty)
          Positioned(
            bottom: 240,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                'No stores found nearby',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStoreMarker(Map<String, dynamic> store) {
    final isSelected = _selectedStore?['id'] == store['id'];
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                left: constraints.maxWidth * (store['x'] as double) - 20,
                top: constraints.maxHeight * (store['y'] as double) - 40,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedStore = store),
                  child: Column(
                    children: [
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.darkGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            store['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.darkGreen : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.darkGreen : AppColors.border,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Iconsax.shop,
                          size: 18,
                          color: isSelected ? Colors.white : AppColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStoreList() {
    final displayStores = _nearbyStores.take(3).toList();
    
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Stores',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${displayStores.length} found',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: displayStores.length,
              itemBuilder: (context, index) => _buildStoreCard(displayStores[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final isSelected = _selectedStore?['id'] == store['id'];
    return GestureDetector(
      onTap: () async {
        // Update marker icon when card is tapped
        final storeId = store['id'] as String;
        
        // Reset previous selection
        if (_selectedStore != null && _selectedStore!['id'] != storeId) {
          final prevStoreId = _selectedStore!['id'] as String;
          final prevStore = _nearbyStores.firstWhere((s) => s['id'] == prevStoreId);
          final prevLogoUrl = prevStore['logoUrl'] as String?;
          BitmapDescriptor unselectedIcon;
          if (prevLogoUrl != null && prevLogoUrl.isNotEmpty) {
            unselectedIcon = await _createLogoMarkerIcon(prevLogoUrl, false);
          } else {
            final prevIcon = _getCategoryIcon(prevStore['category']);
            unselectedIcon = await _createMarkerIcon(prevIcon, false);
          }
          _customIcons[prevStoreId] = unselectedIcon;
        }
        
        // Set new selection
        final logoUrl = store['logoUrl'] as String?;
        BitmapDescriptor selectedIcon;
        if (logoUrl != null && logoUrl.isNotEmpty) {
          selectedIcon = await _createLogoMarkerIcon(logoUrl, true);
        } else {
          final icon = _getCategoryIcon(store['category']);
          selectedIcon = await _createMarkerIcon(icon, true);
        }
        setState(() {
          _customIcons[storeId] = selectedIcon;
          _selectedStore = store;
        });
        
        // Move camera to store
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(store['latitude'], store['longitude']),
            ),
          );
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12, bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (store['logoUrl'] != null && (store['logoUrl'] as String).isNotEmpty)
                        ? Image.network(
                            store['logoUrl'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                _getCategoryIcon(store['category']),
                                size: 20,
                                color: isSelected ? Colors.black : Colors.white,
                              );
                            },
                          )
                        : Icon(
                            _getCategoryIcon(store['category']),
                            size: 20,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _startConversation(store),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Iconsax.message, size: 14, color: isSelected ? Colors.black : Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              store['name'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              store['category'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isSelected ? Colors.white.withValues(alpha: 0.7) : Colors.grey[600],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Iconsax.location, size: 12, color: isSelected ? Colors.white : Colors.black),
                const SizedBox(width: 4),
                Text(
                  store['distanceText'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoreProfileScreen(
                          storeId: store['id'],
                          storeName: store['name'],
                          storeAvatar: store['name'][0],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Iconsax.direct_right, size: 14, color: isSelected ? Colors.black : Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startConversation(Map<String, dynamic> store) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    String userName = 'User';
    String? userPhotoUrl;
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData != null && userData['name'] != null) {
        userName = userData['name'];
      }
      userPhotoUrl = userData?['photoUrl'] as String?;
    } catch (e) {
      if (_auth.currentUser?.displayName != null) {
        userName = _auth.currentUser!.displayName!;
      }
    }

    await _messagesService.getOrCreateConversation(
      storeId: store['id'],
      storeName: store['name'],
      storeLogoUrl: store['logoUrl'],
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoreChatScreen(
            storeId: store['id'],
            storeName: store['name'],
            storeLogoUrl: store['logoUrl'],
          ),
        ),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    
    if (categoryLower.contains('jewelry') || categoryLower.contains('accessories') || categoryLower.contains('accessory')) {
      return Iconsax.crown;
    } else if (categoryLower.contains('fashion') || categoryLower.contains('clothing') || categoryLower.contains('apparel')) {
      return Iconsax.bag_2;
    } else if (categoryLower.contains('electronics') || categoryLower.contains('tech')) {
      return Iconsax.mobile;
    } else if (categoryLower.contains('food') || categoryLower.contains('restaurant') || categoryLower.contains('cafe')) {
      return Iconsax.cake;
    } else if (categoryLower.contains('beauty') || categoryLower.contains('cosmetics')) {
      return Iconsax.brush_2;
    } else if (categoryLower.contains('sports') || categoryLower.contains('fitness') || categoryLower.contains('gym')) {
      return Iconsax.activity;
    } else if (categoryLower.contains('book') || categoryLower.contains('stationery')) {
      return Iconsax.book;
    } else if (categoryLower.contains('home') || categoryLower.contains('furniture')) {
      return Iconsax.home_2;
    } else if (categoryLower.contains('pet')) {
      return Iconsax.pet;
    } else if (categoryLower.contains('health') || categoryLower.contains('pharmacy')) {
      return Iconsax.health;
    } else {
      return Iconsax.shop;
    }
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = const Color(0xFFF5F0E8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines (roads)
    final roadPaint = Paint()
      ..color = const Color(0xFFE8E0D5)
      ..strokeWidth = 2;

    // Horizontal roads
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }

    // Vertical roads
    for (int i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    // Main roads (thicker)
    final mainRoadPaint = Paint()
      ..color = const Color(0xFFD4C9B8)
      ..strokeWidth = 6;

    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      mainRoadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      mainRoadPaint,
    );

    // Building blocks
    final blockPaint = Paint()..color = const Color(0xFFE0D8CC);
    
    // Draw some building blocks
    final blocks = [
      Rect.fromLTWH(size.width * 0.05, size.height * 0.05, size.width * 0.15, size.height * 0.15),
      Rect.fromLTWH(size.width * 0.75, size.height * 0.05, size.width * 0.2, size.height * 0.12),
      Rect.fromLTWH(size.width * 0.05, size.height * 0.75, size.width * 0.12, size.height * 0.2),
      Rect.fromLTWH(size.width * 0.8, size.height * 0.8, size.width * 0.15, size.height * 0.15),
    ];

    for (final block in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(block, const Radius.circular(8)),
        blockPaint,
      );
    }

    // Park area
    final parkPaint = Paint()..color = const Color(0xFFD4E5D0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.6, size.height * 0.55, size.width * 0.15, size.height * 0.15),
        const Radius.circular(12),
      ),
      parkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
