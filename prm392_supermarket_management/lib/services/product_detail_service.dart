import '../models/product_detail.dart';
import 'product_service.dart';
import 'cart_service.dart';

class ProductDetailService {
  static final ProductDetailService _instance = ProductDetailService._internal();
  factory ProductDetailService() => _instance;
  ProductDetailService._internal();
  
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();

  // Mock data for demonstration
  final List<ProductDetail> _mockProducts = [
    ProductDetail(
      id: 1,
      name: 'Studio Wireless Gen 4',
      category: 'Premium Series',
      description: 'Experience sound like never before with the Gen 4 Wireless Studio headphones. Featuring industry-leading noise cancellation, 40-hour battery life, and crystal-clear audio fidelity. Designed for professionals and enthusiasts alike.',
      price: 299.00,
      originalPrice: 349.00,
      discountPercentage: 15,
      imageUrls: [
        'https://lh3.googleusercontent.com/aida-public/AB6AXuD05JtUaB2BTd3lV7nfLGQdd6kshn0HSrZVItzjeJjIoKV8LTH7EqLUni5LOMiyH3DAhBqkiE-zk2bodiGZIOk_a4QN6jUkQjjtqRehkod12ReoWxczTSqLGLBnCiEpg7JaI16MTRK7qfoc-yetwf7n2z0J4q3j9DSYjNaFE5sLNwXgUXiazThH26q3qD7sgdV2zAe6eVK9u8G_IFVxqA-QHGw1SzXbdJ0NKflwjfpuB2iE6T0z3W32XumXG6fJqwCDSxyVBqmpJ-c',
        'https://example.com/headphones2.jpg',
        'https://example.com/headphones3.jpg',
        'https://example.com/headphones4.jpg',
      ],
      rating: 4.8,
      reviewCount: 1200,
      inStock: true,
      availableQuantity: 50,
      features: [
        ProductFeature(
          title: 'Noise Cancellation',
          description: 'Industry-leading active noise cancellation',
          icon: 'volume_off',
        ),
        ProductFeature(
          title: '40-Hour Battery',
          description: 'All-day listening with quick charge',
          icon: 'battery_full',
        ),
        ProductFeature(
          title: 'High-Fidelity Audio',
          description: 'Crystal-clear sound quality',
          icon: 'graphic_eq',
        ),
      ],
    ),
    // Add more mock products as needed
  ];

  final Set<int> _favorites = {};

  /// Get product detail by ID (from database)
  Future<ProductDetail?> getProductDetail(int productId) async {
    try {
      // Get product from database via ProductService
      final product = await _productService.getProductById(productId);
      
      if (product == null) return null;
      
      // Convert Product model to ProductDetail model
      return ProductDetail(
        id: product.id!,
        name: product.name,
        category: product.categoryId.toString(), // You might want to fetch category name
        description: product.description ?? 'No description available',
        price: product.price,
        originalPrice: product.price, // Set same as price if no discount
        discountPercentage: 0,
        imageUrls: product.imageUrl != null ? [product.imageUrl!] : [],
        rating: 4.5, // Default rating - you can add this to Product model later
        reviewCount: 0, // Default - you can add this to Product model later
        inStock: product.stockQuantity > 0,
        availableQuantity: product.stockQuantity,
        features: [], // Can be populated later if needed
      );
    } catch (e) {
      print('Error in getProductDetail: $e');
      return null;
    }
  }

  /// Get related products
  Future<List<ProductDetail>> getRelatedProducts(int productId, {int limit = 5}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _mockProducts
        .where((product) => product.id != productId)
        .take(limit)
        .toList();
  }

  /// Add product to favorites
  Future<bool> addToFavorites(int productId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    _favorites.add(productId);
    return true;
  }

  /// Remove product from favorites
  Future<bool> removeFromFavorites(int productId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    return _favorites.remove(productId);
  }

  /// Check if product is in favorites
  Future<bool> isInFavorites(int productId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    return _favorites.contains(productId);
  }

  /// Add product to cart
  Future<bool> addToCart(int productId, int quantity) async {
    try {
      // TODO: Get userId from auth/session
      const int userId = 1; // Default user for now
      
      await _cartService.addToCart(userId, productId, quantity);
      return true;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }

  /// Get cart items count
  Future<int> getCartItemsCount() async {
    try {
      // TODO: Get userId from auth/session
      const int userId = 1;
      return await _cartService.getCartItemCount(userId);
    } catch (e) {
      print('Error getting cart count: $e');
      return 0;
    }
  }

  /// Get favorites count
  Future<int> getFavoritesCount() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    return _favorites.length;
  }
}