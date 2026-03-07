import '../data/app_database.dart';
import '../models/cart_item.dart';

class CheckoutService {
  final AppDatabase _database = AppDatabase.instance;

  /// Create order from cart items
  Future<int> createOrderFromCart({
    required int userId,
    required int? addressId,
    required List<CartItem> cartItems,
    required double subtotal,
    required double shippingFee,
    required double discount,
    required String paymentMethod,
    String? transactionRef,
  }) async {
    final db = await _database.database;

    try {
      // Calculate total
      final total = subtotal + shippingFee - discount;

      // Generate order code
      final orderCode = _generateOrderCode();

      // Insert order
      final orderId = await db.insert('orders', {
        'user_id': userId,
        'address_id': addressId,
        'order_code': orderCode,
        'status': 'pending',
        'subtotal': subtotal,
        'shipping_fee': shippingFee,
        'total': total,
        'placed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Insert order items
      for (final item in cartItems) {
        await db.insert('order_items', {
          'order_id': orderId,
          'product_id': item.id, // CartItem.id is actually product_id
          'product_name': item.name,
          'unit_price': item.price,
          'quantity': item.quantity,
          'line_total': item.price * item.quantity,
        });
      }

      // Insert payment record
      await db.insert('payments', {
        'order_id': orderId,
        'method': paymentMethod,
        'status': 'completed',
        'paid_amount': total,
        'paid_at': DateTime.now().toIso8601String(),
        'transaction_ref': transactionRef,
      });

      // Clear cart items for this user
      await db.delete(
        'cart_items',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      return orderId;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Generate unique order code
  String _generateOrderCode() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = timestamp % 100000; // Get last 5 digits
    return 'ORD-$random';
  }

  /// Get cart items for user
  Future<List<CartItem>> getCartItems(int userId) async {
    final db = await _database.database;

    final results = await db.rawQuery('''
      SELECT 
        ci.*,
        p.name as product_name,
        p.price,
        p.image_url,
        p.stock_quantity
      FROM cart_items ci
      INNER JOIN products p ON ci.product_id = p.id
      WHERE ci.user_id = ?
    ''', [userId]);

    return results.map((row) => CartItem.fromJson(row)).toList();
  }
}
