import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/screens/chat/chat_screen.dart';
import 'package:marketplace/services/chat_service.dart';
import 'package:marketplace/services/favorite_service.dart';
import 'package:marketplace/services/market_service.dart';
import 'package:marketplace/services/user_session.dart';
import 'package:marketplace/theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final List<MarketProduct>? productList;
  final int? initialIndex;

  const ProductDetailScreen({super.key, this.productList, this.initialIndex});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _currentIndex;
  int _quantity = 1;
  bool _isDescriptionExpanded = false;
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
    return MarketProduct(
      id: '',
      name: 'Farm Produce',
      category: 'Produce',
      location: 'Kenya',
      price: 'Ksh 100',
      freshness: 'Fresh harvest',
      rating: 4.8,
      badge: 'Fresh',
      highlight: false,
      imageColorValue: 0xFF8CCF75,
      mediaUrls: [],
      farmerId: '',
      farmerName: 'Local Farmer',
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

  String get _descriptionText {
    final name = _product.name;
    final cat = _product.category;
    final freshness = _product.freshness;
    final loc = _product.location;
    return '$name are freshly sourced in $loc under premium agricultural conditions. Freshness guaranteed ($freshness), carefully inspected to provide top-tier $cat quality. Ideal for household cooking, organic markets, and healthy farm-to-table nutrition with exceptional taste and natural vitality.';
  }

  void _addToCart() {
    UserSession.addMarketProductToCart(_product, quantity: _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $_quantity x ${_product.name} to cart'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primary,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final mediaUrls = _product.mediaUrls;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: InkWell(
                onTap: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: user != null && _product.farmerId.isNotEmpty
                  ? StreamBuilder<bool>(
                      stream: FavoriteService.isFavoriteStream(
                        user.uid,
                        _product.farmerId,
                      ),
                      builder: (context, snapshot) {
                        final isFav = snapshot.data ?? false;
                        return InkWell(
                          onTap: () {
                            FavoriteService.toggleFavorite(
                              user.uid,
                              _product.farmerId,
                              _product.farmerName,
                              !isFav,
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                        );
                      },
                    )
                  : InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(
                          Icons.bookmark_border_rounded,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroImage(mediaUrls),
              const SizedBox(height: 20),
              _buildTitleAndPrice(),
              const SizedBox(height: 22),
              _buildDescriptionSection(),
              const SizedBox(height: 24),
              _buildRelatedProductsSection(),
              const SizedBox(height: 24),
              _buildFarmerCard(context),
              if (_requiresDeposit) ...[
                const SizedBox(height: 18),
                _buildDepositCard(context),
              ],
              if (UserSession.isBuyer) ...[
                const SizedBox(height: 18),
                _buildRatingCard(),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildHeroImage(List<String> mediaUrls) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (mediaUrls.isEmpty)
              const Center(
                child: Icon(
                  Icons.eco_rounded,
                  size: 72,
                  color: AppTheme.primary,
                ),
              )
            else
              PageView.builder(
                controller: _pageController,
                itemCount: mediaUrls.length,
                onPageChanged: (idx) =>
                    setState(() => _currentImageIndex = idx),
                itemBuilder: (context, idx) {
                  return Image.network(
                    mediaUrls[idx],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            if (mediaUrls.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    mediaUrls.length,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == i ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == i
                            ? AppTheme.primary
                            : Colors.white70,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Available in stock',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppTheme.accentYellow,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_product.rating.toStringAsFixed(1)} (192)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _product.price,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          if (_quantity > 1) {
                            setState(() => _quantity--);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$_quantity pcs',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() => _quantity++);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    final text = _descriptionText;
    final isLong = text.length > 120;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: _isDescriptionExpanded || !isLong
                ? text
                : '${text.substring(0, 115)}... ',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            children: [
              if (isLong)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: () => setState(
                      () => _isDescriptionExpanded = !_isDescriptionExpanded,
                    ),
                    child: Text(
                      _isDescriptionExpanded ? ' Read Less' : 'Read More',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Related Products',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<MarketProduct>>(
          stream: MarketService.streamProducts(),
          builder: (context, snapshot) {
            final list = snapshot.data ?? widget.productList ?? [];
            final related = list
                .where((p) => p.id != _product.id)
                .take(6)
                .toList();

            if (related.isEmpty) {
              return const SizedBox.shrink();
            }

            return SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = related[index];
                  final url = item.mediaUrls.isNotEmpty
                      ? item.mediaUrls.first
                      : null;
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            productList: list,
                            initialIndex: list.indexOf(item),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: url != null
                            ? Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.eco_rounded,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.eco_rounded,
                                  color: AppTheme.primary,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFarmerCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.secondary,
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product.farmerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _product.location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openChat(context),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: const Text('Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: AppTheme.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Initial Deposit',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Deposit required: ${_formatMoney(_depositAmount)} (20% to reserve high-value order)',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showDepositFlow(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Reserve with Deposit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate this produce',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppTheme.accentYellow),
              const SizedBox(width: 8),
              Text(
                (_pendingRating ?? _product.rating).toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Slider(
                  value: (_pendingRating ?? _product.rating).clamp(1.0, 5.0),
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  activeColor: AppTheme.primary,
                  onChanged: (val) => setState(() => _pendingRating = val),
                ),
              ),
              TextButton(
                onPressed: _submitRating,
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Add to cart • ${_formatMoney(_numericPrice * _quantity)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rating submitted successfully!')),
    );
  }

  Future<void> _openChat(BuildContext context) async {
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reserve ${_product.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deposit required: ${_formatMoney(suggested)}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Deposit ${_formatMoney(selectedAmount)} received. Reservation confirmed!',
                            ),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      },
                      child: const Text('Confirm Deposit Payment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatMoney(double value) {
    if (value <= 0) return _product.price;
    return 'Ksh ${value.toStringAsFixed(0)}';
  }
}
