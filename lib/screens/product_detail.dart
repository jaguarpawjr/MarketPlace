import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/screens/chat/chat_screen.dart';
import 'package:marketplace/services/chat_service.dart';
import 'package:marketplace/services/market_service.dart';
import 'package:marketplace/services/user_session.dart';
import 'package:marketplace/models/order.dart';
import 'package:marketplace/services/order_service.dart';
import 'package:marketplace/services/favorite_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final List<MarketProduct>? productList;
  final int? initialIndex;

  const ProductDetailScreen({super.key, this.productList, this.initialIndex});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _currentIndex;
  double? _pendingRating;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  MarketProduct get _product {
    if (widget.productList != null && widget.productList!.isNotEmpty) {
      final idx = _currentIndex.clamp(0, widget.productList!.length - 1);
      return widget.productList![idx];
    }
    // Fallback: construct a minimal product if list not provided (shouldn't happen)
    return MarketProduct(
      id: '',
      name: 'Unknown',
      category: 'Unknown',
      location: 'Unknown',
      price: 'Ghs 0.00',
      freshness: 'Fresh',
      rating: 0.0,
      badge: 'New',
      highlight: false,
      imageColorValue: 0xFF8CCF75,
      mediaUrls: [],
      farmerId: '',
      farmerName: 'Farmer',
      createdAt: DateTime.now(),
    );
  }

  double get _numericPrice {
    final match = RegExp(r'[\d,.]+').firstMatch(_product.price);
    if (match == null) return 0;
    return double.tryParse(match.group(0)!.replaceAll(',', '')) ?? 0;
  }

  bool get _requiresDeposit => _numericPrice > 1000;

  double get _depositAmount => _numericPrice * 0.2;

  void _showNext() {
    if (widget.productList == null) return;
    if (_currentIndex < widget.productList!.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _showPrevious() {
    if (widget.productList == null) return;
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = _product.mediaUrls.isNotEmpty
        ? _product.mediaUrls.first
        : null;
    final isVideo = mediaUrl != null && _isVideo(mediaUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        title: const Text('Product details'),
        backgroundColor: const Color.fromARGB(255, 53, 177, 94),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showPrevious,
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          IconButton(
            onPressed: _showNext,
            icon: const Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMedia(mediaUrl, isVideo),
              const SizedBox(height: 18),
              _buildSummaryCard(context),
              if (UserSession.isBuyer) ...[
                const SizedBox(height: 14),
                _buildBuyerRatingCard(),
              ],
              const SizedBox(height: 14),
              _buildInfoCard(),
              const SizedBox(height: 14),
              _buildFarmerCard(context),
              const SizedBox(height: 14),
              _buildDepositCard(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: UserSession.isBuyer
                ? [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showContactSheet(context),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Chat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPurchaseFlow(context),
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Text('Buy'),
                      ),
                    ),
                  ]
                : [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Keep browsing'),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedia(String? firstMediaUrl, bool isVideo) {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _product.imageColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          if (_product.mediaUrls.isEmpty)
            const Center(
              child: Icon(
                Icons.local_florist_outlined,
                size: 72,
                color: Colors.white70,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _product.mediaUrls.length,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  final url = _product.mediaUrls[index];
                  if (_isVideo(url)) {
                    return const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 76,
                        color: Colors.white,
                      ),
                    );
                  }
                  return Image.network(url, fit: BoxFit.cover, width: double.infinity);
                },
              ),
            ),
          if (_product.mediaUrls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _product.mediaUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 14,
            top: 14,
            child: _pill(_product.category, Icons.category_outlined),
          ),
          if (_product.highlight)
            Positioned(
              right: 14,
              top: 14,
              child: _pill('Featured', Icons.star_outline),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _product.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _product.price,
                  style: const TextStyle(
                    color: Color(0xFF5C3BFF),
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                _product.rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _product.freshness,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerRatingCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buyer rating',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            'Rate this listing from a buyer perspective.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                (_pendingRating ?? _product.rating).toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Slider(
            value: _pendingRating ?? _product.rating.clamp(1.0, 5.0),
            min: 1.0,
            max: 5.0,
            divisions: 8,
            label: (_pendingRating ?? _product.rating).toStringAsFixed(1),
            onChanged: (value) => setState(() => _pendingRating = value),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitRating,
              icon: const Icon(Icons.star_border),
              label: const Text('Submit rating'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _card(
      child: Column(
        children: [
          _detailRow(Icons.place_outlined, 'Location', _product.location),
          const Divider(height: 24),
          _detailRow(Icons.verified_outlined, 'Badge', _product.badge),
          const Divider(height: 24),
          _detailRow(
            Icons.calendar_today_outlined,
            'Listed',
            _formatDate(_product.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerCard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isBuyer = UserSession.isBuyer && user != null;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Farmer',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              if (isBuyer)
                StreamBuilder<bool>(
                  stream: FavoriteService.isFavoriteStream(user.uid, _product.farmerId),
                  builder: (context, snapshot) {
                    final isFavorite = snapshot.data ?? false;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        FavoriteService.toggleFavorite(
                          user.uid,
                          _product.farmerId,
                          _product.farmerName,
                          !isFavorite,
                        );
                      },
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: const Icon(Icons.person_outline, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product.farmerName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Ask about availability, pickup, delivery, or quantity.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showContactSheet(context),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Contact farmer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositCard(BuildContext context) {
    if (!_requiresDeposit) {
      return _card(
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No initial deposit is required for this item.',
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Initial deposit',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'This item is above 1000, so a deposit can reserve it while you confirm details with the farmer.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF5C3BFF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Suggested deposit: ${_formatMoney(_depositAmount)}',
              style: const TextStyle(
                color: Color(0xFF5C3BFF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showDepositFlow(context),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Make initial deposit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black45),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact ${_product.farmerName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a chat with ${_product.farmerName} about ${_product.name}.',
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Start chat'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitRating() async {
    final currentRating = _pendingRating ?? _product.rating;
    if (_product.id.isEmpty) return;

    await MarketService.updateProductRating(
      productId: _product.id,
      rating: currentRating,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Rating submitted')));
  }

  Future<void> _openChat() async {
    Navigator.of(context).pop();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to message the farmer.')),
      );
      return;
    }

    if (_product.farmerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This listing does not have a chat contact yet.'),
        ),
      );
      return;
    }

    final conversation = await ChatService.openConversation(
      buyerId: currentUser.uid,
      farmerId: _product.farmerId,
      buyerName: currentUser.displayName ?? currentUser.email ?? 'Buyer',
      farmerName: _product.farmerName,
      productId: _product.id,
      productName: _product.name,
    );

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(conversation: conversation),
      ),
    );
  }

  void _showDepositFlow(BuildContext context) {
    final suggested = _depositAmount;
    double selectedAmount = suggested;
    String method = 'Mpesa';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reserve ${_product.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Suggested deposit: ${_formatMoney(suggested)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: suggested.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Deposit amount',
                              ),
                              onChanged: (v) {
                                final parsed = double.tryParse(v) ?? suggested;
                                setModalState(() => selectedAmount = parsed);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: method,
                            items: const [
                              DropdownMenuItem(
                                value: 'Mpesa',
                                child: Text('Mpesa'),
                              ),
                              DropdownMenuItem(
                                value: 'Card',
                                child: Text('Card'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setModalState(() => method = v);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final snack = SnackBar(
                              content: Text(
                                'Processing deposit ${_formatMoney(selectedAmount)} via $method...',
                              ),
                              duration: const Duration(seconds: 2),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(snack);
                            await Future.delayed(const Duration(seconds: 2));
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Deposit successful for ${_product.name}',
                                ),
                              ),
                            );
                          },
                          child: const Text('Confirm deposit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPurchaseFlow(BuildContext context) {
    int quantity = 1;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final totalPrice = _numericPrice * quantity;
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase ${_product.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantity:'),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (quantity > 1) {
                                    setModalState(() => quantity--);
                                  }
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('$quantity', style: const TextStyle(fontSize: 16)),
                              IconButton(
                                onPressed: () {
                                  setModalState(() => quantity++);
                                },
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Total Price: ${_formatMoney(totalPrice)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5C3BFF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            
                            final order = OrderModel(
                              id: '',
                              productId: _product.id,
                              productName: _product.name,
                              productImageUrl: _product.mediaUrls.isNotEmpty ? _product.mediaUrls.first : '',
                              farmerId: _product.farmerId,
                              buyerId: user.uid,
                              quantity: quantity,
                              price: totalPrice,
                              orderStatus: 'Pending',
                              timestamp: DateTime.now(),
                            );
                            
                            await OrderService.createOrder(order);
                            
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Order placed successfully!')),
                            );
                          },
                          child: const Text('Confirm Purchase'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatMoney(double value) {
    if (value <= 0) return 'Amount to be confirmed';
    return 'Ksh ${value.toStringAsFixed(0)}';
  }
}
