import '../models/cart_item.dart';
import '../models/suggested_product.dart';
import '../services/cart_service.dart';

class CartRepository {
  final CartService _cartService = CartService();

  Future<List<CartItem>> getCartItems(int userId) {
    return _cartService.getCartItems(userId);
  }

  Future<List<SuggestedProduct>> getSuggestedProducts(int userId) {
    return _cartService.getSuggestedProducts(userId);
  }

  double getShippingFeeThreshold() {
    return _cartService.getShippingFeeThreshold();
  }

  double calculateShippingFee(double subtotal) {
    return _cartService.calculateShippingFee(subtotal);
  }

  Future<void> updateQuantity(int userId, int productId, int newQuantity) {
    return _cartService.updateQuantity(userId, productId, newQuantity);
  }

  Future<void> removeItem(int userId, int productId) {
    return _cartService.removeItem(userId, productId);
  }

  Future<void> addToCart(int userId, int productId, int quantity) {
    return _cartService.addToCart(userId, productId, quantity);
  }

  Future<void> clearCart(int userId) {
    return _cartService.clearCart(userId);
  }

  Future<int> getCartItemCount(int userId) {
    return _cartService.getCartItemCount(userId);
  }

  double calculateSubtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double calculateTotal(List<CartItem> items) {
    final subtotal = calculateSubtotal(items);
    final shippingFee = calculateShippingFee(subtotal);
    return subtotal + shippingFee;
  }

  double calculateFreeShippingProgress(List<CartItem> items) {
    final subtotal = calculateSubtotal(items);
    final threshold = getShippingFeeThreshold();
    final progress = (subtotal / threshold).clamp(0.0, 1.0);
    return progress;
  }

  double calculateRemainingForFreeShipping(List<CartItem> items) {
    final subtotal = calculateSubtotal(items);
    final threshold = getShippingFeeThreshold();
    final remaining = threshold - subtotal;
    return remaining > 0 ? remaining : 0.0;
  }
}
