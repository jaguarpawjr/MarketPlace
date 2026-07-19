import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marketplace/theme.dart';
import 'package:flutter/services.dart';
import 'package:marketplace/services/market_service.dart';
import 'package:marketplace/services/weather_service.dart';
import 'package:marketplace/screens_buyer/orders.dart';
import 'package:marketplace/screens_buyer/profile.dart';
import 'package:marketplace/screens_buyer/marketplace_buyer.dart';
import 'package:marketplace/screens/ai_chat.dart';

class HomePageBuyer extends StatefulWidget {
  const HomePageBuyer({super.key});

  @override
  State<HomePageBuyer> createState() => _HomePageBuyerState();
}

class _HomePageBuyerState extends State<HomePageBuyer> {
  int _index = 0;
  bool _loadingWeather = false;
  String? _weatherError;
  WeatherData? _weather;

  static const List<Widget> _pages = <Widget>[
    Center(child: Text('Home content (placeholder)')),
    MarketplaceScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  // Quick actions for buyer homepage
  final List<_HomeAction> _actions = const [
    _HomeAction(
      label: 'Marketplace',
      icon: Icons.storefront_outlined,
      tabIndex: 1,
    ),
    _HomeAction(
      label: 'Orders',
      icon: Icons.shopping_cart_outlined,
      tabIndex: 2,
    ),
    _HomeAction(label: 'Profile', icon: Icons.person_outline, tabIndex: 3),
    _HomeAction(label: 'Weather', icon: Icons.cloud_outlined, tabIndex: null),
  ];

  final List<BuyerTip> _tips = [];
  int _tipIndex = 0;

  @override
  // Load weather and tips when the homepage is initialized
  void initState() {
    super.initState();
    _loadTips();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;
    setState(() {
      _loadingWeather = true;
      _weatherError = null;
    });
    // Users should eventually be able to choose a preferred location.
    // For now, this demo uses Accra, Ghana.
    try {
      final data = await WeatherService.fetchWeather(lat: 5.6037, lon: -0.1870);
      if (!mounted) return;
      setState(() => _weather = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _weatherError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingWeather = false);
      }
    }
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

  void _onActionTap(_HomeAction action) {
    if (action.tabIndex != null) {
      setState(() {
        _index = action.tabIndex!;
      });
    } else {
      _loadWeather();
    }
  }

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationScreen()));
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning,';
    if (hour >= 12 && hour < 17) return 'Good afternoon,';
    if (hour >= 17 && hour < 21) return 'Good evening,';
    return 'Good night,';
  }

  String _displayName() {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
    return name != null && name.isNotEmpty ? name : 'Buyer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? 'Marketplace' : _navTitle()),
        backgroundColor: const Color.fromARGB(255, 53, 177, 94),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: _openNotifications,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.authGradient()),
        child: SafeArea(
          child: _index == 0
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildHome(),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _pages[_index],
                ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: const Color.fromARGB(255, 53, 177, 129),
        unselectedItemColor: Colors.black54,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 53, 177, 94),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AIChatScreen()));
        },
        child: const Icon(Icons.smart_toy_outlined),
      ),
    );
  }

  String _navTitle() {
    switch (_index) {
      case 1:
        return 'Browse market';
      case 2:
        return 'Orders';
      case 3:
        return 'Profile';
      default:
        return 'Marketplace';
    }
  }

  Widget _buildHome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_greeting(), style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          '${_displayName()} 👋',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Fresh products, saved orders, and local market updates in one place.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 20),
        _buildMetricRow(),
        const SizedBox(height: 16),
        _buildFoodstuffCarousel(),
        const SizedBox(height: 20),
        _buildQuickActions(),
        const SizedBox(height: 20),
        _buildOfferSection(),
        const SizedBox(height: 20),
        _buildFarmTipCard(),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildMetricRow() {
    return Row(
      children: [
        _buildMetricTile('Fresh picks', 'Today', Icons.eco_outlined),
        const SizedBox(width: 12),
        _buildMetricTile('Orders', 'Track easily', Icons.receipt_long_outlined),
      ],
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.deepPurple.shade700),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodstuffCarousel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Swipe foodstuffs',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Browse produce cards from the market feed.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: PageView.builder(
              itemCount: _foodstuffCards.length,
              controller: PageController(viewportFraction: 0.86),
              itemBuilder: (context, index) {
                final food = _foodstuffCards[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [food.color, food.color.withOpacity(0.78)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              food.emoji,
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                food.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                food.subtitle,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.swipe,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Swipe for more',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick actions',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3.4,
          children: _actions.map((action) {
            return GestureDetector(
              onTap: () => _onActionTap(action),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        action.icon,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action.label,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOfferSection() {
    return StreamBuilder<List<MarketProduct>>(
      stream: MarketService.streamProducts(featuredOnly: true),
      builder: (context, snapshot) {
        final offers = snapshot.hasData ? snapshot.data! : [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What\'s fresh and available today',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            offers.isEmpty
                ? _buildFeaturedEmptyState()
                : SizedBox(
                    height: 260,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: offers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final offer = offers[index];
                        final imageUrl = offer.mediaUrls.isNotEmpty
                            ? offer.mediaUrls.first
                            : null;
                        final isVideo =
                            imageUrl != null && _isVideoUrl(imageUrl);
                        return Container(
                          width: 180,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.grey.shade200,
                                  image: imageUrl != null && !isVideo
                                      ? DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: imageUrl != null && isVideo
                                    ? const Center(
                                        child: Icon(
                                          Icons.videocam_outlined,
                                          size: 40,
                                          color: Colors.black54,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                offer.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                offer.price,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () => setState(() => _index = 1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Browse'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.storefront_outlined,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'No featured products yet. Browse the full marketplace to see what is available.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm');
  }

  Widget _buildFarmTipCard() {
    final tip = _tips.isNotEmpty
        ? _tips[_tipIndex]
        : BuyerTip(
            id: 0,
            tip:
                "Always verify the farmer or seller profile before purchasing farm produce online.",
            timeInterval: 'daily morning',
            touchGesture: 'tap',
          );

    return GestureDetector(
      onTap: _showNextTip,
      onLongPress: _showPreviousTip,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < 0) {
          _showNextTip();
        } else {
          _showPreviousTip();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily buyer tip',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              tip.tip,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Time: ${tip.timeInterval} • Gesture: ${tip.touchGesture}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Swipe left/right to cycle tips, tap to advance, long press to go back.',
              style: TextStyle(color: Colors.black38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(DateTime dt) {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final now = DateTime.now();
    final diff = DateTime(
      dt.year,
      dt.month,
      dt.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return names[dt.weekday % 7];
  }
}

class _HomeAction {
  final String label;
  final IconData icon;
  final int? tabIndex;

  const _HomeAction({required this.label, required this.icon, this.tabIndex});
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Reports')),
      body: const Center(child: Text('Help and reports content coming soon.')),
    );
  }
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

class _FoodstuffCard {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;

  const _FoodstuffCard({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
  });
}

const List<_FoodstuffCard> _foodstuffCards = [
  _FoodstuffCard(
    title: 'Fresh Tomatoes',
    subtitle: 'Bright, ripe, and ready for stew, salads, and sauces.',
    emoji: '🍅',
    color: Color(0xFFE53935),
  ),
  _FoodstuffCard(
    title: 'Plantain Bunch',
    subtitle: 'Sweet plantains for boiling, frying, or roasting.',
    emoji: '🍌',
    color: Color(0xFFF9A825),
  ),
  _FoodstuffCard(
    title: 'Yam Tubers',
    subtitle: 'A staple choice for porridge, fufu, and yam fries.',
    emoji: '🥔',
    color: Color(0xFF8D6E63),
  ),
  _FoodstuffCard(
    title: 'Maize & Corn',
    subtitle: 'Perfect for roasted corn, flour, and local dishes.',
    emoji: '🌽',
    color: Color(0xFF43A047),
  ),
  _FoodstuffCard(
    title: 'Garden Eggs',
    subtitle: 'Small fresh harvests for soups and traditional meals.',
    emoji: '🍆',
    color: Color(0xFF7E57C2),
  ),
];
