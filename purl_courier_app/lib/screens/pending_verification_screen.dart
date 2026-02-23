import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class PendingVerificationScreen extends StatefulWidget {
  const PendingVerificationScreen({super.key});

  @override
  State<PendingVerificationScreen> createState() => _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('couriers')
            .doc(_authService.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final status = data?['status'] ?? 'pending_verification';
          final verification = data?['verification'] as Map<String, dynamic>?;
          final verificationStatus = verification?['status'] ?? 'pending';

          // If verified, go to home
          if (status == 'verified') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/home');
            });
          }

          // If rejected, show rejection reason
          if (verificationStatus == 'rejected') {
            final reason = verification?['rejectionReason'] ?? 'Please resubmit your documents';
            return _buildRejectedView(reason);
          }

          // Show pending view
          return _buildPendingView();
        },
      ),
    );
  }

  Widget _buildPendingView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.document_text,
                size: 80,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Under Verification',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Your application is being reviewed by our team. This usually takes 24-48 hours.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // Status Steps
            _buildStatusStep('Application Submitted', true),
            _buildStatusStep('Documents Under Review', true),
            _buildStatusStep('Verification Complete', false),
            
            const Spacer(),
            
            // Customer Support Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Add customer support contact (WhatsApp, Email, etc.)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact support: support@pop.co.za'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Iconsax.message),
                label: const Text('Customer Support'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sign Out Button
            OutlinedButton(
              onPressed: () async {
                await _authService.signOut();
                if (mounted) context.go('/welcome');
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedView(String reason) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.close_circle,
                size: 80,
                color: Colors.red[600],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Verification Failed',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reason,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.red[900],
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/verification'),
                child: const Text('Resubmit Documents'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            OutlinedButton(
              onPressed: () async {
                await _authService.signOut();
                if (mounted) context.go('/welcome');
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(String title, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: completed ? Colors.black : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
                  color: completed ? Colors.black : Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}
