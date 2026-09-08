import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketplace/screens/ai_chat.dart';
import 'package:marketplace/screens/cart.dart';
import 'package:marketplace/screens/product_detail.dart';
import 'package:marketplace/screens/services_screen.dart';
import 'package:marketplace/screens/support/support_tickets_screen.dart';
import 'package:marketplace/screens_buyer/orders.dart';
import 'package:marketplace/screens_buyer/profile.dart';
import 'package:marketplace/screens_farmer/esp32_camera_screen.dart';
import 'package:marketplace/services/favorite_service.dart';
import 'package:marketplace/services/market_service.dart';
import 'package:marketplace/services/user_session.dart';
import 'package:marketplace/theme.dart';

class HomePageBuyer extends StatefulWidget {
  const HomePageBuyer({super.key});

  @override
  State<HomePageBuyer> createState() => _HomePageBuyerState();
}

class _HomePageBuyerState extends State<HomePageBuyer> {
  int _index = 0;
  final TextEditingController _searchController = TextEditingController();
  final List<BuyerTip> _tips = [];
  int _tipIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTips() async {
    try {
      final jsonString = await rootBundle.loadString('assets/buyer_tips.json');
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final tips = jsonList
          .cast<Map<String, dynamic>>()
          .map((map) => BuyerTip.fromJson(map))
          .toList();
      if (!mounted) return;
      setState(() {
        _tips.clear();
        _tips.addAll(tips);
        _tipIndex = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tips.clear();
      });
    }
  }

  void _showNextTip() {
    if (_tips.isEmpty) return;
    setState(() {
      _tipIndex = (_tipIndex + 1) % _tips.length;
    });
  }

  void _showPreviousTip() {
    if (_tips.isEmpty) return;
    setState(() {
      _tipIndex = (_tipIndex - 1 + _tips.length) % _tips.length;
    });
  }

  String _displayName() {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name.split(' ').first;
    }
    return 'Wilson';
  }

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationScreen()));
  }

  void _navigateToMarketplace({String? category, String? query}) {
    setState(() => _index = 1);
  }

  void _openProductDetails(MarketProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailScreen(productList: [product], initialIndex: 0),
      ),
    );
  }

  void _addToCart(MarketProduct product) {
    UserSession.addMarketProductToCart(product);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.name} to cart'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () => setState(() => _index = 2),
        ),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeContent(),
      ServicesScreen(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onNotificationTap: _openNotifications,
        onCategorySelected: (category) =>
            _navigateToMarketplace(category: category),
      ),
      const CartPage(),
      const ProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      drawer: _buildDrawer(),
      body: pages[_index],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final cartCount = UserSession.cart.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.storefront_rounded, 'Services'),
              _buildCartNavItem(
                2,
                Icons.shopping_cart_outlined,
                'Cart',
                cartCount,
              ),
              _buildNavItem(3, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _index == index;
    return InkWell(
      onTap: () => setState(() => _index = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : const Color(0xFF9CA3AF),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : const Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartNavItem(int index, IconData icon, String label, int count) {
    final isSelected = _index == index;
    return InkWell(
      onTap: () => setState(() => _index = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppTheme.primary
                      : const Color(0xFF9CA3AF),
                  size: 24,
                ),
                if (count > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.badgeRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : const Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildSearchAndFilter(),
            const SizedBox(height: 20),
            _buildFreeConsultationBanner(),
            const SizedBox(height: 24),
            _buildFeaturedProductsSection(),
            const SizedBox(height: 24),
            _buildFarmTipCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
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
              Icons.menu_rounded,
              color: AppTheme.textPrimary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Hi ${_displayName()}!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('👋', style: TextStyle(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Enjoy our services!',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: _openNotifications,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.textPrimary,
                  size: 22,
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.badgeRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  _navigateToMarketplace(query: query.trim());
                }
              },
              decoration: const InputDecoration(
                hintText: 'Search here...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 22,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () => _navigateToMarketplace(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFreeConsultationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Free Consultation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Get free support from our customer service',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AIChatScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Call Now',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Image(image: AssetImage('assets/customer_care.jpeg')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToMarketplace(),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        StreamBuilder<List<MarketProduct>>(
          stream: MarketService.streamProducts(featuredOnly: true),
          builder: (context, snapshot) {
            var items = snapshot.data ?? [];
            if (items.isEmpty) {
              items = _fallbackFeaturedProducts;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length > 4 ? 4 : items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
                childAspectRatio: 0.74,
              ),
              itemBuilder: (context, index) {
                final product = items[index];
                return _buildFeaturedProductCard(product);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedProductCard(MarketProduct product) {
    final imageUrl = product.mediaUrls.isNotEmpty
        ? product.mediaUrls.first
        : null;
    final currentUser = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: () => _openProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Container(
                    height: 125,
                    width: double.infinity,
                    color: const Color(0xFFF3F4F6),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.eco_rounded,
                                color: AppTheme.primary,
                                size: 36,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.eco_rounded,
                              color: AppTheme.primary,
                              size: 36,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: currentUser != null && product.farmerId.isNotEmpty
                      ? StreamBuilder<bool>(
                          stream: FavoriteService.isFavoriteStream(
                            currentUser.uid,
                            product.farmerId,
                          ),
                          builder: (context, snapshot) {
                            final isFav = snapshot.data ?? false;
                            return Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  isFav
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.bookmark_border_rounded,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),
                        ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      InkWell(
                        onTap: () => _addToCart(product),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmTipCard() {
    final tip = _tips.isNotEmpty
        ? _tips[_tipIndex]
        : const BuyerTip(
            id: 0,
            tip:
                "Always verify the farmer or seller profile before purchasing farm produce online.",
            timeInterval: 'daily morning',
            touchGesture: 'tap',
          );

    return GestureDetector(
      onTap: _showNextTip,
      onLongPress: _showPreviousTip,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.lightbulb_rounded,
                  color: AppTheme.accentYellow,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Daily buyer tip',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tip.tip,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFEAF8F1)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      _displayName().substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FirebaseAuth.instance.currentUser?.displayName ??
                              'Valued Buyer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FirebaseAuth.instance.currentUser?.email ??
                              'buyer@marketplace.com',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.primary,
              ),
              title: const Text('My Orders'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.storefront_rounded,
                color: AppTheme.primary,
              ),
              title: const Text('Browse Market'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToMarketplace();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.smart_toy_rounded,
                color: AppTheme.primary,
              ),
              title: const Text('AI Farming Assistant'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AIChatScreen()));
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppTheme.primary,
              ),
              title: const Text('Plant Disease Detection'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const Esp32CameraScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.support_agent_rounded,
                color: AppTheme.primary,
              ),
              title: const Text('Support & Tickets'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const SupportTicketsScreen(userType: 'buyer'),
                  ),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Log Out',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  static final List<MarketProduct> _fallbackFeaturedProducts = [
    MarketProduct(
      id: 'rice_seeds',
      name: 'Rice Seeds',
      category: 'Seeds',
      location: 'Mwea, Kenya',
      price: '\$15/kg',
      freshness: 'Certified seeds',
      rating: 4.9,
      badge: 'Certified',
      highlight: true,
      imageColorValue: 0xFFE0E7FF,
      mediaUrls: [
        'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=600&auto=format&fit=crop&q=80',
      ],
      farmerId: 'farmer_1',
      farmerName: 'Green Valley Agro',
      createdAt: DateTime.now(),
    ),
    MarketProduct(
      id: 'lime_seedlings',
      name: 'Lime Seedlings',
      category: 'Seedlings',
      location: 'Kilifi, Kenya',
      price: '\$5/pcs',
      freshness: 'Nursery fresh',
      rating: 4.9,
      badge: 'Popular',
      highlight: true,
      imageColorValue: 0xFFDCFCE7,
      mediaUrls: [
        'https://images.unsplash.com/photo-1592417817098-8f3d6ef23a80?w=600&auto=format&fit=crop&q=80',
      ],
      farmerId: 'farmer_2',
      farmerName: 'Sunshine Nursery',
      createdAt: DateTime.now(),
    ),
    MarketProduct(
      id: 'tractor_equipment',
      name: 'Farm Tractor',
      category: 'Machinery',
      location: 'Eldoret, Kenya',
      price: '\$45/day',
      freshness: 'Serviced',
      rating: 4.8,
      badge: 'Rental',
      highlight: true,
      imageColorValue: 0xFFFEF3C7,
      mediaUrls: [
        'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=600&auto=format&fit=crop&q=80',
      ],
      farmerId: 'farmer_3',
      farmerName: 'Agro Machinery Ltd',
      createdAt: DateTime.now(),
    ),
    MarketProduct(
      id: 'bean_seeds',
      name: 'Bean Seeds',
      category: 'Seeds',
      location: 'Kitale, Kenya',
      price: '\$8/kg',
      freshness: 'High yield',
      rating: 4.7,
      badge: 'Verified',
      highlight: true,
      imageColorValue: 0xFFFEE2E2,
      mediaUrls: [
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&auto=format&fit=crop&q=80',
      ],
      farmerId: 'farmer_4',
      farmerName: 'Highland Farms',
      createdAt: DateTime.now(),
    ),
  ];
}

class BuyerTip {
  final int id;
  final String tip;
  final String timeInterval;
  final String touchGesture;

  const BuyerTip({
    required this.id,
    required this.tip,
    required this.timeInterval,
    required this.touchGesture,
  });

  factory BuyerTip.fromJson(Map<String, dynamic> json) {
    return BuyerTip(
      id: json['id'] as int,
      tip: json['tip'] as String,
      timeInterval: json['timeInterval'] as String,
      touchGesture: json['touchGesture'] as String,
    );
  }
}
