import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Deliveries'),
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveDeliveries(),
          _buildCompletedDeliveries(),
          _buildAllDeliveries(),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveries() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDeliveryCard(
          id: 'DEL-2026-045',
          storeName: 'Semakula Baker',
          pickupAddress: 'Kampala Road, Shop 12',
          dropoffAddress: 'Ntinda, House 45',
          amount: 'UGX 15,000',
          distance: '5.2 km',
          status: 'In Transit',
          statusColor: Colors.black,
          time: '10 mins ago',
        ),
        _buildDeliveryCard(
          id: 'DEL-2026-046',
          storeName: 'Fresh Mart',
          pickupAddress: 'Garden City Mall',
          dropoffAddress: 'Kololo, Apartment 8B',
          amount: 'UGX 12,000',
          distance: '3.8 km',
          status: 'Picked Up',
          statusColor: Colors.grey[700]!,
          time: '25 mins ago',
        ),
      ],
    );
  }

  Widget _buildCompletedDeliveries() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDeliveryCard(
          id: 'DEL-2026-044',
          storeName: 'Tech Store',
          pickupAddress: 'Oasis Mall',
          dropoffAddress: 'Bugolobi, Street 5',
          amount: 'UGX 18,000',
          distance: '7.1 km',
          status: 'Delivered',
          statusColor: Colors.grey[600]!,
          time: '2 hours ago',
        ),
        _buildDeliveryCard(
          id: 'DEL-2026-043',
          storeName: 'Fashion Hub',
          pickupAddress: 'Acacia Mall',
          dropoffAddress: 'Nakasero, Office Block',
          amount: 'UGX 10,000',
          distance: '4.5 km',
          status: 'Delivered',
          statusColor: Colors.grey[600]!,
          time: '5 hours ago',
        ),
        _buildDeliveryCard(
          id: 'DEL-2026-042',
          storeName: 'Book Store',
          pickupAddress: 'City Center',
          dropoffAddress: 'Makerere, Hostel 3',
          amount: 'UGX 8,000',
          distance: '2.9 km',
          status: 'Delivered',
          statusColor: Colors.grey[600]!,
          time: 'Yesterday',
        ),
      ],
    );
  }

  Widget _buildAllDeliveries() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDeliveryCard(
          id: 'DEL-2026-045',
          storeName: 'Semakula Baker',
          pickupAddress: 'Kampala Road, Shop 12',
          dropoffAddress: 'Ntinda, House 45',
          amount: 'UGX 15,000',
          distance: '5.2 km',
          status: 'In Transit',
          statusColor: Colors.black,
          time: '10 mins ago',
        ),
        _buildDeliveryCard(
          id: 'DEL-2026-044',
          storeName: 'Tech Store',
          pickupAddress: 'Oasis Mall',
          dropoffAddress: 'Bugolobi, Street 5',
          amount: 'UGX 18,000',
          distance: '7.1 km',
          status: 'Delivered',
          statusColor: Colors.grey[600]!,
          time: '2 hours ago',
        ),
        _buildDeliveryCard(
          id: 'DEL-2026-043',
          storeName: 'Fashion Hub',
          pickupAddress: 'Acacia Mall',
          dropoffAddress: 'Nakasero, Office Block',
          amount: 'UGX 10,000',
          distance: '4.5 km',
          status: 'Delivered',
          statusColor: Colors.grey[600]!,
          time: '5 hours ago',
        ),
      ],
    );
  }

  Widget _buildDeliveryCard({
    required String id,
    required String storeName,
    required String pickupAddress,
    required String dropoffAddress,
    required String amount,
    required String distance,
    required String status,
    required Color statusColor,
    required String time,
  }) {
    return GestureDetector(
      onTap: () => context.push('/tracking'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  id,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Iconsax.shop, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    storeName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Iconsax.location, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pickupAddress,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Iconsax.location_tick, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dropoffAddress,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.routing, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(Iconsax.clock, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
