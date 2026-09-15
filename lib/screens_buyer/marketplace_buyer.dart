import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace/screens/product_detail.dart';
import 'package:marketplace/services/market_service.dart';
import 'package:marketplace/services/user_session.dart';

import 'package:marketplace/theme.dart';

class MarketplaceScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialSearch;

  const MarketplaceScreen({
    super.key,
    this.initialCategory,
    this.initialSearch,
  });

  @override
  State<MarketplaceScreen> createState() => MarketplaceScreenState();
}

class MarketplaceScreenState extends State<MarketplaceScreen> {
  int _selectedTab = 0;
  int _selectedCategory = 0;
  final _searchController = TextEditingController();

  List<String> get _categories => [
    'All',
    'Crops',
    'Vegetables',
    'Fruits',
    'Seeds',
    'Seedlings',
    'Machinery',
    'Dairy',
    'Herbs',
  ];
  List<String> get _tabs =>
      UserSession.isFarmer ? ['Browse', 'My listings'] : ['Browse'];
  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  void applyFilter({String? category, String? query}) {
    setState(() {
      if (category != null) {
        final idx = _categories.indexWhere(
          (c) => c.toLowerCase() == category.toLowerCase(),
        );
        if (idx != -1) {
          _selectedCategory = idx;
        } else {
          _selectedCategory = 0;
        }
      }
      if (query != null) {
        _searchController.text = query;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchController.text = widget.initialSearch!;
    }
    if (widget.initialCategory != null) {
      applyFilter(category: widget.initialCategory);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MarketProduct> _filterProducts(List<MarketProduct> products) {
    final query = _searchController.text.toLowerCase();
    final selectedCat = _selectedCategory > 0
        ? _categories[_selectedCategory].toLowerCase()
        : null;

    var list = products.where((product) {
      if (selectedCat != null && selectedCat != 'all') {
        final prodCat = product.category.toLowerCase();
        if (selectedCat == 'crops') {
          // 'Crops' category matches all agricultural produce
          if (prodCat != 'crops' &&
              prodCat != 'vegetables' &&
              prodCat != 'fruits' &&
              prodCat != 'produce' &&
              prodCat != 'seeds' &&
              prodCat != 'seedlings') {
            return false;
          }
        } else if (prodCat != selectedCat) {
          return false;
        }
      }
      if (query.isNotEmpty &&
          !product.name.toLowerCase().contains(query) &&
          !product.category.toLowerCase().contains(query) &&
          !product.farmerName.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    if (UserSession.isFarmer && _selectedTab == 1) {
      list = list
          .where((product) => product.farmerId == _currentUserId)
          .toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedTab >= _tabs.length) {
      _selectedTab = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 18),
        _buildSearchBar(),
        const SizedBox(height: 18),
        _buildCategoryChips(),
        const SizedBox(height: 20),
        if (_tabs.length > 1) _buildTabBar(),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<List<MarketProduct>>(
            stream: MarketService.streamProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }
              var products = snapshot.data ?? [];
              if (products.isEmpty) {
                products = _defaultMarketplaceProducts;
              }

              final displayed = _filterProducts(products);
              if (displayed.isEmpty) {
                return _buildEmptyState();
              }

              return _buildProductGrid(displayed);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Marketplace',
                style: TextStyle(
                  fontSize: 26,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Browse fresh produce from local farmers',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        if (UserSession.isFarmer)
          ElevatedButton.icon(
            onPressed: _openAddListing,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('List Produce'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search produce, category or farm...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9CA3AF),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = index == _selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = index),
            selectedColor: AppTheme.primary,
            backgroundColor: Colors.white,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
            side: BorderSide(
              color: selected ? AppTheme.primary : const Color(0xFFE5E7EB),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final selected = index == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.shopping_basket_outlined,
            size: 60,
            color: AppTheme.primary,
          ),
          SizedBox(height: 14),
          Text(
            'No items found',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different category or search term.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  static final List<MarketProduct> _defaultMarketplaceProducts = [
    MarketProduct(
      id: 'fresh_tomatoes',
      name: 'Fresh Tomatoes',
      category: 'Crops',
      location: 'Uasin Gishu, Kenya',
      price: 'Ksh 45/kg',
      freshness: 'Just harvested',
      rating: 4.8,
      badge: 'Fresh',
      highlight: true,
      imageColorValue: 0xFFFEE2E2,
      mediaUrls: [
        'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&auto=format&fit=crop&q=80',
      ],
      farmerId: 'farmer_1',
      farmerName: 'Eldoret Greens',
      createdAt: DateTime.now(),
    ),
    MarketProduct(
      id: 'sweet_bananas',
      name: 'Sweet Bananas',
      category: 'Crops',
      location: 'Kisii, Kenya',
      price: 'Ksh 120/bunch',
      freshness: 'Farm ripe',
      rating: 4.7,
      badge: 'Sweet',
      highlight: false,
      imageColorValue: 0xFFFEF3C7,
      mediaUrls: [
        'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=600&auto=format&fit=crop&q=80',
      ],
      farmerId: 'farmer_2',
      farmerName: 'Kisii Harvest',
      createdAt: DateTime.now(),
    ),
    MarketProduct(
      id: 'white_maize',
      name: 'White Maize',
      category: 'Crops',
      location: 'Trans Nzoia, Kenya',
      price: 'Ksh 60/kg',
      freshness: 'Sun dried',
      rating: 4.8,
      badge: 'Staple',
      highlight: false,
      imageColorValue: 0xFFFEF08A,
      mediaUrls: [
        'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=600&auto=format&fit=crop&q=80',
      ],
      farmerId: 'farmer_3',
      farmerName: 'Kitale Grain Farms',
      createdAt: DateTime.now(),
    ),
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
      farmerId: 'farmer_4',
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
      farmerId: 'farmer_5',
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
      farmerId: 'farmer_6',
      farmerName: 'Agro Machinery Ltd',
      createdAt: DateTime.now(),
    ),
    MarketProduct(
      id: 'yam_tubers',
      name: 'Yam Tubers',
      category: 'Crops',
      location: 'Meru, Kenya',
      price: 'Ksh 150/piece',
      freshness: 'Organically grown',
      rating: 4.6,
      badge: 'Organic',
      highlight: false,
      imageColorValue: 0xFFE2E8F0,
      mediaUrls: [
        'https://images.unsplash.com/photo-1596797882870-8c33deeac224?w=600&auto=format&fit=crop&q=80',
      ],
      farmerId: 'farmer_7',
      farmerName: 'Meru Farmers Co-op',
      createdAt: DateTime.now(),
    ),
  ];

  Widget _buildProductGrid(List<MarketProduct> products) {
    return GridView.builder(
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () => _openProductDetail(products, index),
          onLongPress: _canManageListing(product)
              ? () => _editListing(product)
              : null,
          child: _buildProductCard(product),
        );
      },
    );
  }

  Widget _buildProductCard(MarketProduct product) {
    final firstMediaUrl = product.mediaUrls.isNotEmpty
        ? product.mediaUrls.first
        : null;
    final isVideo = firstMediaUrl != null && _isVideo(firstMediaUrl);
    final isMyListing = _canManageListing(product);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 135,
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: product.imageColor,
              image: firstMediaUrl != null && !isVideo
                  ? DecorationImage(
                      image: NetworkImage(firstMediaUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Stack(
              children: [
                if (firstMediaUrl != null && isVideo)
                  const Center(
                    child: Icon(
                      Icons.videocam_outlined,
                      size: 56,
                      color: Colors.white70,
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.bookmark_border_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                  ),
                ),
                if (product.highlight)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.accentYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isMyListing)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editListing(product);
                        } else if (value == 'delete') {
                          _deleteListing(product);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit listing'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete listing'),
                        ),
                      ],
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 4),
                Text(
                  product.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      child: Text(
                        product.freshness,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppTheme.accentYellow,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.price,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        UserSession.addMarketProductToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${product.name} to cart'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppTheme.primaryLight,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
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
    );
  }

  void _openProductDetail(List<MarketProduct> products, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailScreen(productList: products, initialIndex: index),
      ),
    );
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm');
  }

  void _openAddListing() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddListingScreen()))
        .then((_) => setState(() {}));
  }

  bool _canManageListing(MarketProduct product) {
    return UserSession.isFarmer && product.farmerId == _currentUserId;
  }

  Future<void> _editListing(MarketProduct product) async {
    await Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AddListingScreen(productToEdit: product),
          ),
        )
        .then((_) => setState(() {}));
  }

  Future<void> _deleteListing(MarketProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete listing?'),
          content: Text('Remove ${product.name} from your market listings?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await MarketService.deleteProduct(product.id);
    if (!mounted) return;
    setState(() {});
  }
}

class AddListingScreen extends StatefulWidget {
  final MarketProduct? productToEdit;

  const AddListingScreen({super.key, this.productToEdit});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _freshnessController = TextEditingController();
  final _badgeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedMedia = [];
  String _category = 'Vegetables';
  bool _highlight = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.productToEdit != null) {
      final product = widget.productToEdit!;
      _nameController.text = product.name;
      _locationController.text = product.location;
      _priceController.text = product.price;
      _freshnessController.text = product.freshness;
      _badgeController.text = product.badge;
      _category = product.category;
      _highlight = product.highlight;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _freshnessController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 75);
    if (images.isNotEmpty) {
      setState(() {
        _selectedMedia.addAll(images);
      });
    }
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedMedia.add(video);
      });
    }
  }

  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw StateError('You must be signed in to list produce.');
      }

      // Upload new media files if any were selected
      final newMediaUrls = await MarketService.uploadMediaFiles(_selectedMedia);

      // Use existing media if editing and no new media was selected
      final mediaUrls = _selectedMedia.isEmpty && widget.productToEdit != null
          ? widget.productToEdit!.mediaUrls
          : newMediaUrls;

      final product = MarketProduct(
        id: widget.productToEdit?.id ?? '',
        name: _nameController.text.trim(),
        category: _category,
        location: _locationController.text.trim(),
        price: _priceController.text.trim(),
        freshness: _freshnessController.text.trim().isNotEmpty
            ? _freshnessController.text.trim()
            : 'Fresh today',
        rating: widget.productToEdit?.rating ?? 0.0,
        badge: _badgeController.text.trim().isNotEmpty
            ? _badgeController.text.trim()
            : 'New',
        highlight: _highlight,
        imageColorValue: widget.productToEdit?.imageColorValue ?? 0xFF8CCF75,
        mediaUrls: mediaUrls,
        farmerId: currentUser.uid,
        farmerName: currentUser.displayName ?? 'Farmer',
        createdAt: widget.productToEdit?.createdAt ?? DateTime.now(),
      );
      await MarketService.saveProduct(product);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productToEdit == null ? 'Create listing' : 'Edit listing',
        ),
        backgroundColor: const Color.fromARGB(255, 53, 177, 94),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(_nameController, 'Crop name'),
                const SizedBox(height: 14),
                _buildTextField(_locationController, 'Location'),
                const SizedBox(height: 14),
                _buildTextField(_priceController, 'Price e.g. Ksh 120/kg'),
                const SizedBox(height: 14),
                _buildTextField(_freshnessController, 'Freshness note'),
                const SizedBox(height: 14),
                _buildTextField(_badgeController, 'Badge (e.g. Best seller)'),
                const SizedBox(height: 14),
                _buildCategoryDropdown(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Highlight listing',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: _highlight,
                      onChanged: (value) => setState(() => _highlight = value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Media',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Add photos'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Add video'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_selectedMedia.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected media',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedMedia.map((file) {
                          final isVideo = file.path.toLowerCase().endsWith(
                            '.mp4',
                          );
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isVideo ? Icons.videocam : Icons.image,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveListing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 53, 177, 94),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save listing'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 53, 177, 94),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter ${label.toLowerCase()}';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      items: ['Vegetables', 'Fruits', 'Dairy', 'Herbs']
          .map((label) => DropdownMenuItem(value: label, child: Text(label)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _category = value);
        }
      },
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      dropdownColor: const Color.fromARGB(255, 53, 177, 94),
      style: const TextStyle(color: Colors.white),
    );
  }
}
