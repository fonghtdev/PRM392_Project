import '../models/product_detail.dart';
import '../services/product_detail_service.dart';

class ProductDetailRepository {
  static final ProductDetailRepository _instance = ProductDetailRepository._internal();
  factory ProductDetailRepository() => _instance;
  ProductDetailRepository._internal();

  final ProductDetailService _service = ProductDetailService();

  /// Get product detail by ID
  Future<ProductDetail?> getProductDetail(int productId) async {
    try {
      return await _service.getProductDetail(productId);
    } catch (e) {
      print('Error in ProductDetailRepository.getProductDetail: $e');
      return null;
    }
  }

  /// Get related products
  Future<List<ProductDetail>> getRelatedProducts(int productId, {int limit = 5}) async {
    try {
      return await _service.getRelatedProducts(productId, limit: limit);
    } catch (e) {
      print('Error in ProductDetailRepository.getRelatedProducts: $e');
      return [];
    }
  }

  /// Add product to favorites
  Future<bool> addToFavorites(int productId) async {
    try {
      return await _service.addToFavorites(productId);
    } catch (e) {
      print('Error in ProductDetailRepository.addToFavorites: $e');
      return false;
    }
  }

  /// Remove product from favorites
  Future<bool> removeFromFavorites(int productId) async {
    try {
      return await _service.removeFromFavorites(productId);
    } catch (e) {
      print('Error in ProductDetailRepository.removeFromFavorites: $e');
      return false;
    }
  }

  /// Check if product is in favorites
  Future<bool> isInFavorites(int productId) async {
    try {
      return await _service.isInFavorites(productId);
    } catch (e) {
      print('Error in ProductDetailRepository.isInFavorites: $e');
      return false;
    }
  }

  /// Add product to cart
  Future<bool> addToCart(int productId, int quantity) async {
    try {
      return await _service.addToCart(productId, quantity);
    } catch (e) {
      print('Error in ProductDetailRepository.addToCart: $e');
      return false;
    }
  }
}