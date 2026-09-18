import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/models/order.dart';
import 'package:marketplace/screens/order_detail.dart';
import 'package:marketplace/services/order_service.dart';
import 'package:marketplace/services/paystack_payment_service.dart';
import 'package:marketplace/services/user_session.dart';
import 'package:marketplace/theme.dart';
import 'package:marketplace/screens_buyer/profile.dart';
import 'package:marketplace/user_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isProcessing = false;
  final Set<String> _selectedCartIds = {};
  final Set<String> _selectedOrderIds = {};

  Future<void> _requestApproval() async {
    final cartItems = UserSession.cart;
    if (cartItems.isEmpty) return;

    final selectedItems = cartItems
        .where((i) => _selectedCartIds.contains(i.product.id))
        .toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select items to request approval.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before checkout.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final checkoutId = 'checkout_${DateTime.now().millisecondsSinceEpoch}';
      for (final item in selectedItems) {
        await OrderService.createOrder(
          OrderModel(
            id: '',
            productId: item.product.id,
            productName: item.product.name,
            productImageUrl: item.product.imageUrl ?? '',
            farmerId: item.product.farmerId,
            buyerId: user.uid,
            quantity: item.quantity,
            price: item.totalPrice,
            orderStatus: 'Pending',
            timestamp: DateTime.now(),
            checkoutId: checkoutId,
          ),
        );
        UserSession.removeFromCart(item.product);
      }

      _selectedCartIds.clear();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order sent for approval'),
          content: const Text(
            'Your items have been sent for approval. Payment will be available after the farmer approves each order.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval request failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));

      // Re-check profile after returning from EditProfileScreen
      final updatedProfile = await UserService.getUserProfile(user.uid);
      if (updatedProfile?.email != null &&
          updatedProfile!.email!.trim().isNotEmpty) {
        return updatedProfile.email!.trim();
      }
    }

    return null;
  }

  Future<void> _bulkPay(List<OrderModel> orders) async {
    final selectedOrders = orders
        .where((o) => _selectedOrderIds.contains(o.id))
        .toList();
    if (selectedOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select approved orders to pay.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in to pay.')));
      return;
    }

    final email = await _getOrPromptEmail(user);
    if (email == null || email.isEmpty) {
      return;
    }

    final total = selectedOrders.fold(0.0, (acc, o) => acc + o.price);

    setState(() => _isProcessing = true);
    try {
      await PaystackPaymentService.startCheckout(
        orderId: selectedOrders.first.id,
        amount: total,
        buyerEmail: email,
        orderIds: selectedOrders.map((order) => order.id).toList(),
      );

      _selectedOrderIds.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _removeSelectedCartItems() {
    final itemsToRemove = UserSession.cart
        .where((i) => _selectedCartIds.contains(i.product.id))
        .toList();
    for (final item in itemsToRemove) {
      UserSession.removeFromCart(item.product);
    }
    _selectedCartIds.clear();
    setState(() {});
  }

  void _openOrder(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final cartItems = UserSession.cart;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Your Cart & Orders',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: userId == null
          ? const Center(child: Text('Please sign in to view your cart.'))
          : StreamBuilder<List<OrderModel>>(
              stream: OrderService.streamBuyerOrders(userId),
              builder: (context, snapshot) {
                final orders = snapshot.data ?? const <OrderModel>[];

                if (cartItems.isEmpty && orders.isEmpty) {
                  return const Center(
                    child: Text('Your cart and orders are empty.'),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    if (cartItems.isNotEmpty) _buildCartSection(cartItems),
                    if (orders.isNotEmpty) _buildOrdersSection(orders),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCartSection(List<CartItem> cartItems) {
    final allSelected = _selectedCartIds.length == cartItems.length;
    final totalSelectedValue = cartItems
        .where((i) => _selectedCartIds.contains(i.product.id))
        .fold(0.0, (sum, i) => sum + i.totalPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cart Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Text('Select All', style: TextStyle(fontSize: 14)),
                  Checkbox(
                    activeColor: AppTheme.primary,
                    value: allSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedCartIds.addAll(
                            cartItems.map((i) => i.product.id),
                          );
                        } else {
                          _selectedCartIds.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        ...cartItems.map((item) {
          final isSelected = _selectedCartIds.contains(item.product.id);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.grey.shade200,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    activeColor: AppTheme.primary,
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedCartIds.add(item.product.id);
                        } else {
                          _selectedCartIds.remove(item.product.id);
                        }
                      });
                    },
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.product.imageUrl == null
                        ? Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.eco_outlined,
                              color: AppTheme.primary,
                            ),
                          )
                        : Image.network(
                            item.product.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                  ),
                ],
              ),
              title: Text(
                item.product.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'GHC ${item.product.price} • Qty ${item.quantity}',
              ),
              trailing: Text(
                'GHC ${item.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          );
        }),
        if (_selectedCartIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _removeSelectedCartItems,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  label: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _requestApproval,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Request (${totalSelectedValue.toStringAsFixed(0)})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildOrdersSection(List<OrderModel> orders) {
    final pendingOrders = orders
        .where((o) => o.orderStatus == 'Pending')
        .toList();
    final approvedOrders = orders
        .where((o) => o.orderStatus == 'Accepted')
        .toList();
    final paidOrders = orders.where((o) => o.orderStatus == 'Paid').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (approvedOrders.isNotEmpty)
          _buildApprovedOrdersSection(approvedOrders),
        if (pendingOrders.isNotEmpty)
          _buildListSection('Pending Approval', pendingOrders, Colors.orange),
        if (paidOrders.isNotEmpty)
          _buildListSection('Paid Orders', paidOrders, Colors.green),
      ],
    );
  }

  Widget _buildApprovedOrdersSection(List<OrderModel> approvedOrders) {
    final allSelected =
        _selectedOrderIds.length == approvedOrders.length &&
        approvedOrders.isNotEmpty;
    final totalPayable = approvedOrders
        .where((o) => _selectedOrderIds.contains(o.id))
        .fold(0.0, (sum, o) => sum + o.price);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ready for Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Text('Select All', style: TextStyle(fontSize: 14)),
                  Checkbox(
                    activeColor: const Color(0xFF5C3BFF),
                    value: allSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedOrderIds.addAll(
                            approvedOrders.map((o) => o.id),
                          );
                        } else {
                          _selectedOrderIds.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        ...approvedOrders.map((order) {
          final isSelected = _selectedOrderIds.contains(order.id);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF5C3BFF)
                    : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              onTap: () => _openOrder(order),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    activeColor: const Color(0xFF5C3BFF),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedOrderIds.add(order.id);
                        } else {
                          _selectedOrderIds.remove(order.id);
                        }
                      });
                    },
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: order.productImageUrl.isEmpty
                        ? Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.grey,
                            ),
                          )
                        : Image.network(
                            order.productImageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                  ),
                ],
              ),
              title: Text(
                order.productName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Qty ${order.quantity}'),
              trailing: Text(
                'GHC ${order.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF5C3BFF),
                ),
              ),
            ),
          );
        }),
        if (_selectedOrderIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _bulkPay(approvedOrders),
                icon: const Icon(Icons.payment, color: Colors.white),
                label: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Pay Selected (GHC ${totalPayable.toStringAsFixed(0)})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C3BFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildListSection(
    String title,
    List<OrderModel> ordersList,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        ...ordersList.map((order) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              onTap: () => _openOrder(order),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: order.productImageUrl.isEmpty
                    ? Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: accentColor,
                        ),
                      )
                    : Image.network(
                        order.productImageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
              ),
              title: Text(
                order.productName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Qty ${order.quantity} • ${order.orderStatus}'),
              trailing: Text(
                'GHC ${order.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: accentColor,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
