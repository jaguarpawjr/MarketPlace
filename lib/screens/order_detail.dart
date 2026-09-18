import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/models/order.dart';
import 'package:marketplace/services/order_service.dart';
import 'package:marketplace/services/paystack_payment_service.dart';
import 'package:marketplace/screens_buyer/profile.dart';
import 'package:marketplace/user_service.dart';
import 'package:marketplace/theme.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late String _currentStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.orderStatus;
  }

  bool get _isBuyer {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == widget.order.buyerId;
  }

  bool get _isFarmer {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == widget.order.farmerId;
  }

  Future<void> _updateStatus(String newStatus, String successMessage) async {
    setState(() => _isLoading = true);
    try {
      if (widget.order.id.isNotEmpty) {
        await OrderService.updateOrderStatus(widget.order.id, newStatus);
      }
      setState(() => _currentStatus = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _getOrPromptEmail(User user) async {
    // 1. Check FirebaseAuth email
    if (user.email != null && user.email!.trim().isNotEmpty) {
      return user.email!.trim();
    }

    // 2. Check Firestore profile email
    final profile = await UserService.getUserProfile(user.uid);
    if (profile?.email != null && profile!.email!.trim().isNotEmpty) {
      return profile.email!.trim();
    }

    // 3. Prompt user & redirect to EditProfileScreen if missing
    if (!mounted) return null;
    final bool? shouldRedirect = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Address Required'),
        content: const Text(
          'An email address is required to process payments and send receipts. Please update your profile to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Profile'),
          ),
        ],
      ),
    );

    if (shouldRedirect == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
        ),
      );

      // Re-check profile after returning from EditProfileScreen
      final updatedProfile = await UserService.getUserProfile(user.uid);
      if (updatedProfile?.email != null && updatedProfile!.email!.trim().isNotEmpty) {
        return updatedProfile.email!.trim();
      }
    }

    return null;
  }

  Future<void> _startPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final email = await _getOrPromptEmail(user);
    if (email == null || email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await PaystackPaymentService.startCheckout(
        orderId: widget.order.id,
        amount: widget.order.price,
        buyerEmail: email,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: const Color.fromARGB(255, 53, 177, 94),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductSummary(),
              const SizedBox(height: 16),
              _buildStatusTracker(),
              const SizedBox(height: 24),
              _buildActionArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.order.productImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.order.productImageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 40),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.order.productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quantity: ${widget.order.quantity}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: GHC ${widget.order.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C3BFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatusStep(
            'Pending',
            'Order placed by buyer',
            _currentStatus == 'Pending' ||
                _currentStatus == 'Accepted' ||
                _currentStatus == 'Paid',
          ),
          _buildStatusLine(),
          _buildStatusStep(
            'Accepted',
            'Farmer confirmed order',
            _currentStatus == 'Accepted' || _currentStatus == 'Paid',
          ),
          _buildStatusLine(),
          _buildStatusStep(
            'Paid',
            'Payment completed',
            _currentStatus == 'Paid',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(String title, String subtitle, bool isCompleted) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusLine() {
    return Container(
      margin: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      width: 2,
      height: 20,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildActionArea() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isFarmer && _currentStatus == 'Pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus('Accepted', 'Order accepted!'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color.fromARGB(255, 53, 177, 94),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Accept Order',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_isBuyer && _currentStatus == 'Accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _startPayment,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF5C3BFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Pay with Paystack',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_isBuyer && _currentStatus == 'Pending') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Waiting for farmer approval. Payment will be available once this order is approved.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentStatus == 'Paid') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'This order has been fully paid.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
