import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'withdraw_screen.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Earnings'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Iconsax.calendar),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('couriers')
            .doc(userId)
            .snapshots(),
        builder: (context, courierSnapshot) {
          if (!courierSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courierData = courierSnapshot.data?.data() as Map<String, dynamic>?;
          final totalEarnings = (courierData?['totalEarnings'] ?? 0.0).toDouble();
          final totalDeliveries = courierData?['totalDeliveries'] ?? 0;
          final rating = (courierData?['rating'] ?? 0.0).toDouble();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('deliveries')
                .where('assignedCourierId', isEqualTo: userId)
                .where('status', isEqualTo: 'delivered')
                .orderBy('deliveredAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, deliveriesSnapshot) {
              final deliveries = deliveriesSnapshot.data?.docs ?? [];

              // Calculate earnings for different periods
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final weekStart = today.subtract(Duration(days: today.weekday - 1));
              final monthStart = DateTime(now.year, now.month, 1);

              double todayEarnings = 0;
              double weekEarnings = 0;
              double monthEarnings = 0;

              for (var doc in deliveries) {
                final data = doc.data() as Map<String, dynamic>;
                final deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate();
                final fee = (data['deliveryFee'] ?? 0).toDouble();

                if (deliveredAt != null) {
                  if (deliveredAt.isAfter(today)) {
                    todayEarnings += fee;
                  }
                  if (deliveredAt.isAfter(weekStart)) {
                    weekEarnings += fee;
                  }
                  if (deliveredAt.isAfter(monthStart)) {
                    monthEarnings += fee;
                  }
                }
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Total Earnings Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFfb2a0a),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Total Earnings',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'UGX ${totalEarnings.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(context, 'Today', 'UGX ${todayEarnings.toStringAsFixed(0)}'),
                              Container(width: 1, height: 40, color: Colors.white24),
                              _buildStatItem(context, 'This Week', 'UGX ${weekEarnings.toStringAsFixed(0)}'),
                              Container(width: 1, height: 40, color: Colors.white24),
                              _buildStatItem(context, 'This Month', 'UGX ${monthEarnings.toStringAsFixed(0)}'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Quick Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuickStatCard(
                              context,
                              icon: Iconsax.truck_fast,
                              label: 'Deliveries',
                              value: '$totalDeliveries',
                              subtitle: 'This month',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickStatCard(
                              context,
                              icon: Iconsax.star,
                              label: 'Rating',
                              value: rating.toStringAsFixed(1),
                              subtitle: 'Average',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recent Transactions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Transaction List from Firestore
                    if (deliveries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Iconsax.wallet, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    else
                      ...deliveries.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final orderNumber = data['orderNumber'] ?? 'N/A';
                        final deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate();
                        final fee = (data['deliveryFee'] ?? 0).toDouble();
                        
                        String dateStr = 'Unknown';
                        if (deliveredAt != null) {
                          final diff = now.difference(deliveredAt);
                          if (diff.inDays == 0) {
                            dateStr = 'Today, ${DateFormat('HH:mm').format(deliveredAt)}';
                          } else if (diff.inDays == 1) {
                            dateStr = 'Yesterday, ${DateFormat('HH:mm').format(deliveredAt)}';
                          } else {
                            dateStr = DateFormat('MMM dd, yyyy').format(deliveredAt);
                          }
                        }

                        return _buildTransactionItem(
                          context,
                          id: orderNumber,
                          date: dateStr,
                          amount: '+ UGX ${fee.toStringAsFixed(0)}',
                          status: 'Completed',
                        );
                      }).toList(),

                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WithdrawScreen()),
          );
        },
        backgroundColor: const Color(0xFFb71000),
        icon: const Icon(Iconsax.wallet_add, color: Colors.white),
        label: const Text(
          'Withdraw',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
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
          Icon(icon, size: 24, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context, {
    required String id,
    required String date,
    required String amount,
    required String status,
    bool isWithdrawal = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isWithdrawal ? Iconsax.wallet_minus : Iconsax.wallet_add,
              size: 24,
              color: isWithdrawal ? Colors.grey[700] : Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isWithdrawal ? Colors.grey[700] : Colors.black,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
