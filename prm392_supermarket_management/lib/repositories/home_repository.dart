import '../models/category.dart';
import '../models/product.dart';
import '../services/home_service.dart';

class HomeRepository {
  final HomeService _service = HomeService();

  /// Get all categories
  Future<List<Category>> getCategories() {
    return _service.getCategories();
  }

  /// Get featured products
  Future<List<Product>> getFeaturedProducts({int limit = 10}) {
    return _service.getFeaturedProducts(limit: limit);
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(int categoryId, {int limit = 10}) {
    return _service.getProductsByCategory(categoryId, limit: limit);
  }

  /// Search products
  Future<List<Product>> searchProducts(String query) {
    return _service.searchProducts(query);
  }

  /// Add product to cart
  Future<void> addToCart(int userId, int productId, {int quantity = 1}) {
    return _service.addToCart(userId, productId, quantity: quantity);
  }

  /// Toggle favorite
  Future<void> toggleFavorite(int userId, int productId) {
    return _service.toggleFavorite(userId, productId);
  }
}
