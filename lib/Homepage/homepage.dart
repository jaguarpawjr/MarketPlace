import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketplace/theme.dart';
import 'package:marketplace/services/market_service.dart';
import 'package:marketplace/services/weather_service.dart';
import 'package:marketplace/screens/marketplace.dart';
import 'package:marketplace/screens/ai_chat.dart';
import 'package:marketplace/screens/disease_detection.dart';
import 'package:marketplace/screens_farmer/profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  bool _loadingWeather = false;
  String? _weatherError;
  WeatherData? _weather;

  static const List<Widget> _pages = <Widget>[
    Center(child: Text('Home content (placeholder)')),
    MarketplaceScreen(),
    AIChatScreen(),
    DiseaseDetectionScreen(),
    FarmerProfileScreen(),
  ];

  final List<_HomeAction> _actions = const [
    _HomeAction(
      label: 'Marketplace',
      icon: Icons.storefront_outlined,
      tabIndex: 1,
    ),
    _HomeAction(
      label: 'AI Agent',
      icon: Icons.chat_bubble_outline,
      tabIndex: 2,
    ),
    _HomeAction(label: 'Detect', icon: Icons.camera_alt_outlined, tabIndex: 3),
    _HomeAction(label: 'Weather', icon: Icons.cloud_outlined, tabIndex: null),
  ];

  final List<FarmTip> _tips = [];
  int _tipIndex = 0;

  @override
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

    try {
      final data = await WeatherService.fetchWeather(
        lat: 37.419,
        lon: -122.057,
      );
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
      final jsonString = await rootBundle.loadString('assets/farm_tips.json');
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final tips = jsonList
          .cast<Map<String, dynamic>>()
          .map((map) => FarmTip.fromJson(map))
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
      setState(() => _index = action.tabIndex!);
    } else {
      _loadWeather();
    }
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
    return name != null && name.isNotEmpty ? name : 'Farmer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? 'Smart Farmer' : _navTitle()),
        backgroundColor: const Color.fromARGB(255, 53, 177, 94),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
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
            icon: Icon(Icons.chat_bubble_outline),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: 'Detect',
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
        return 'Marketplace';
      case 2:
        return 'Farm assistant';
      case 3:
        return 'Disease detection';
      case 4:
        return 'Profile';
      default:
        return 'Smart Farmer';
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
          'A curated farm dashboard for your daily decisions.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 20),
        _buildMetricRow(),
        const SizedBox(height: 16),
        _buildWeatherCard(),
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
        _buildMetricTile('Soil moisture', '68%', Icons.water_drop_outlined),
        const SizedBox(width: 12),
        _buildMetricTile(
          'Market price',
          'Ksh 345/kg',
          Icons.trending_up_outlined,
        ),
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

  Widget _buildWeatherCard() {
    if (_loadingWeather) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    if (_weatherError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weather update',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _weatherError!,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadWeather, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_weather == null || _weather!.daily.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Weather data is not available yet.',
          style: TextStyle(color: Colors.black87),
        ),
      );
    }

    final current = _weather!.series.isNotEmpty ? _weather!.series.first : null;
    final daily = _weather!.daily.length > 5
        ? _weather!.daily.sublist(0, 5)
        : _weather!.daily;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${current?.tempC ?? '--'}°C',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${current?.rh2m ?? '--'}% humidity • ${current?.windSpeed ?? '--'} km/h',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  Icon(Icons.wb_sunny, size: 42, color: Colors.amber.shade700),
                  const SizedBox(height: 4),
                  const Text('Today', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '5-day forecast',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: daily.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final d = daily[i];
                final label = _weekdayLabel(d.date);
                return Container(
                  width: 110,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Icon(Icons.wb_sunny, color: Colors.amber.shade700),
                      const SizedBox(height: 8),
                      Text(
                        '${d.tempMax ?? '--'}° / ${d.tempMin ?? '--'}°',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
              'Featured offers',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            offers.isEmpty
                ? _buildFeaturedEmptyState()
                : SizedBox(
                    height: 300,
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
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
                                child: const Text('View market'),
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
              'No featured offers yet. Open the marketplace to create or manage listings.',
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
        : FarmTip(
            id: 0,
            tip:
                'Water your seedlings in the early morning to reduce evaporation and strengthen root growth.',
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
              'Daily farm tip',
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

class FarmTip {
  final int id;
  final String tip;
  final String timeInterval;
  final String touchGesture;

  const FarmTip({
    required this.id,
    required this.tip,
    required this.timeInterval,
    required this.touchGesture,
  });

  factory FarmTip.fromJson(Map<String, dynamic> json) {
    return FarmTip(
      id: json['id'] as int,
      tip: json['tip'] as String,
      timeInterval: json['timeInterval'] as String,
      touchGesture: json['touchGesture'] as String,
    );
  }
}
