import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace/screens/product_detail.dart';
import 'package:marketplace/services/market_service.dart';
import 'package:marketplace/services/user_session.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  int _selectedTab = 0;
  int _selectedCategory = 0;
  final _searchController = TextEditingController();

  List<String> get _categories => [
    'All',
    'Vegetables',
    'Fruits',
    'Dairy',
    'Herbs',
  ];
  List<String> get _tabs =>
      UserSession.isFarmer ? ['Browse', 'My listings'] : ['Browse'];
  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MarketProduct> _filterProducts(List<MarketProduct> products) {
    final query = _searchController.text.toLowerCase();
    var list = products.where((product) {
      if (_selectedCategory > 0 &&
          product.category != _categories[_selectedCategory]) {
        return false;
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
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Failed to load products',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final products = snapshot.data ?? [];
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Marketplace',
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Browse fresh produce from local farmers',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        if (UserSession.isFarmer)
          ElevatedButton.icon(
            onPressed: _openAddListing,
            icon: const Icon(Icons.add),
            label: const Text('List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search produce, category or farm',
          prefixIcon: const Icon(Icons.search_outlined),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = index == _selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = index),
            selectedColor: const Color.fromARGB(255, 238, 237, 238),
            backgroundColor: Colors.white24,
            labelStyle: TextStyle(
              color: selected ? Colors.deepPurple.shade700 : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
            side: const BorderSide(color: Colors.transparent),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: List.generate(_tabs.length, (index) {
        final selected = index == _selectedTab;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.white24,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    color: selected ? Colors.deepPurple.shade700 : Colors.white,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.shopping_basket_outlined, size: 60, color: Colors.white30),
          SizedBox(height: 14),
          Text(
            'No items found',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different category or search term.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<MarketProduct> products) {
    return GridView.builder(
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 10,
        childAspectRatio: 0.6,
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

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
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
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.badge,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (product.highlight)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isMyListing)
                  Positioned(
                    right: 12,
                    bottom: 12,
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
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.location,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        product.freshness,
                        style: TextStyle(
                          color: Colors.deepPurple.shade700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.price,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return card;
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
