import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../repositories/home_repository.dart';
import 'app_bottom_nav.dart';
import 'product_category_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeRepository _repository = HomeRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<Category> _categories = [];
  List<Product> _featuredProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Hardcoded userId - TODO: Get from auth service
  final int _userId = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final categories = await _repository.getCategories();
      final products = await _repository.getFeaturedProducts(limit: 4);

      setState(() {
        _categories = categories;
        _featuredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart(Product product) async {
    try {
      await _repository.addToCart(_userId, product.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchSubmitted(String query) {
    // Navigate to search results or category screen with filter
    if (query.trim().isNotEmpty) {
      Navigator.pushNamed(
        context,
        ProductCategoryScreen.routeName,
        arguments: {'searchQuery': query},
      );
    }
  }

  void _navigateToCategory(Category category) {
    Navigator.pushNamed(
      context,
      ProductCategoryScreen.routeName,
      arguments: {'categoryId': category.id, 'categoryName': category.name},
    );
  }

  void _navigateToProductDetail(Product product) {
    Navigator.pushNamed(
      context,
      ProductDetailScreen.routeName,
      arguments: product.id,
    );
  }

  void _navigateToAllProducts() {
    Navigator.pushNamed(context, ProductCategoryScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildContent(isDark),
      bottomNavigationBar: const CustomerBottomNav(currentRoute: HomeScreen.routeName),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return CustomScrollView(
      slivers: [
        // Header
        _buildHeader(isDark),
        
        // Promotional Banners
        _buildBanners(),
        
        // Categories Section
        _buildCategories(isDark),
        
        // Featured Products
        _buildFeaturedProducts(isDark),
        
        // Bottom padding
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: true,
      elevation: 0,
      expandedHeight: 180,
      toolbarHeight: 180,
      titleSpacing: 0,
      backgroundColor: isDark 
          ? const Color(0xFF101622).withOpacity(0.8) 
          : const Color(0xFFF6F6F8).withOpacity(0.8),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: isDark 
              ? const Color(0xFF101622).withOpacity(0.8) 
              : const Color(0xFFF6F6F8).withOpacity(0.8),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Title Row
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag,
                      color: Color(0xFF135BEC),
                      size: 30,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ShopEase',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    // Notification Button
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          color: isDark ? Colors.white : Colors.black,
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF1E293B).withOpacity(0.5)
                        : const Color(0xFFE2E8F0).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: 'Search products, brands...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey : const Color(0xFF64748B),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? Colors.grey : const Color(0xFF64748B),
                      ),
                      suffixIcon: Icon(
                        Icons.mic_outlined,
                        color: isDark ? Colors.grey : const Color(0xFF64748B),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanners() {
    return SliverToBoxAdapter(
      child: Container(
        height: 160,
        margin: const EdgeInsets.only(top: 16),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            _buildBanner(
              gradient: const LinearGradient(
                colors: [Color(0xFF135BEC), Color(0xFF60A5FA)],
              ),
              title: 'Summer Sale',
              subtitle: 'Up to 50% Off',
              label: 'Limited Time',
              buttonText: 'Shop Now',
              imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDd_vA9LjrQG8kn-z0HvRNaN3Quqm1CMLU0BkGqFSOVO22vrR_ZyUZaDv491EOb07BbnvvvGV_ZuIypWMe8Joe7_NEC-4_HTRjtCBI82H7JwgoHxgsCKNRoaSamfkke2YgElpNcA7t5l9x38_C8OHGGvh9icsswlLpW7mHlQDwTOJ6NYW8-4FuB5PegfKd5X4ag14oP1epegxN69QSOSK3dJ3YC1Jipcii6ryFl_R12iOEpyYqX9gqrzsGXgzxVtstOjWYeuRwUehQ',
            ),
            const SizedBox(width: 16),
            _buildBanner(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF475569)],
              ),
              title: 'Tech Deals',
              subtitle: 'Upgrade your workspace',
              imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBAfRevPqBP3uu01BYk8LpnkDVVHEFrQxCpvCC3IQfHvhhFHZYlORRCf4eABjBb0n7mx1hCHg05pA7CxQ01BwvspvJyrAugpDZ4-6i79nJ2XxqeZjeCiJqnnkPYSkrTqVC5CL4T-J12kP2IOFmbVJ0CZ6YEd0MqEGvdyblFYewwtZJT59GLZ9K9jLYiUXyIl6eFSoD7zd5y4sIVVGc_xDKnFDphzPPx4ScA-oTi0ehLmd0QNPgGLOM-daxmdTYIq5fb7bc0Jaon8Cw',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner({
    required Gradient gradient,
    required String title,
    required String subtitle,
    String? label,
    String? buttonText,
    required String imageUrl,
  }) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
      ),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.3),
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.transparent),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null)
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                if (label != null) const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFE5E7EB),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (buttonText != null) ...[
                  const SizedBox(height: 6),
                  ElevatedButton(
                    onPressed: _navigateToAllProducts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF135BEC),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      minimumSize: const Size(0, 26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(bool isDark) {
    if (_categories.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Map category names to icons and colors
    final categoryIcons = {
      'Electronics': {'icon': Icons.laptop_mac, 'color': Colors.orange},
      'Food': {'icon': Icons.restaurant, 'color': Colors.green},
      'Cosmetics': {'icon': Icons.face, 'color': Colors.pink},
      'Fashion': {'icon': Icons.checkroom, 'color': Colors.blue},
      'Home': {'icon': Icons.chair, 'color': Colors.purple},
      'Games': {'icon': Icons.sports_esports, 'color': Colors.yellow},
    };

    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: _navigateToAllProducts,
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF135BEC),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Categories List
          SizedBox(
            height: 100,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final categoryData = categoryIcons[category.name] ?? 
                    {'icon': Icons.category, 'color': Colors.grey};
                return _buildCategoryItem(
                  category,
                  categoryData['icon'] as IconData,
                  categoryData['color'] as Color,
                  isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    Category category,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => _navigateToCategory(category),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark 
                    ? color.withOpacity(0.3)
                    : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts(bool isDark) {
    if (_featuredProducts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: _navigateToAllProducts,
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF135BEC),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Products Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _featuredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_featuredProducts[index], isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isDark) {
    // Get category name for display
    final category = _categories.firstWhere(
      (c) => c.id == product.categoryId,
      orElse: () => Category(
        name: 'General',
        createdAt: DateTime.now(),
      ),
    );

    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark 
                ? const Color(0xFF334155) 
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: product.imageUrl != null
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: isDark 
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 48,
                              ),
                            ),
                          )
                        : Container(
                            color: isDark 
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            child: const Icon(
                              Icons.shopping_bag,
                              size: 48,
                            ),
                          ),
                  ),
                ),
                
                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.favorite_border,
                        size: 18,
                      ),
                      color: isDark ? Colors.black : Colors.black87,
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
            ),
            
            // Product Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark 
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF135BEC),
                          ),
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF135BEC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                          onPressed: () => _addToCart(product),
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
}
