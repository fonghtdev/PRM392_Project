import '../data/app_database.dart';
import '../models/order.dart';
import '../models/payment.dart';

class OrderSuccessService {
  final AppDatabase _database = AppDatabase.instance;

  /// Get order details by ID including order items
  Future<Order?> getOrderById(int orderId) async {
    final db = await _database.database;

    // Get order data
    final orderResults = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );

    if (orderResults.isEmpty) {
      return null;
    }

    final orderData = orderResults.first;

    // Get order items
    final itemsResults = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    final items = itemsResults
        .map((item) => OrderItem.fromJson(item))
        .toList();

    // Combine order with items
    final orderJson = Map<String, dynamic>.from(orderData);
    orderJson['items'] = items.map((item) => item.toJson()).toList();

    return Order.fromJson(orderJson);
  }

  /// Get order by order code
  Future<Order?> getOrderByCode(String orderCode) async {
    final db = await _database.database;

    final orderResults = await db.query(
      'orders',
      where: 'order_code = ?',
      whereArgs: [orderCode],
    );

    if (orderResults.isEmpty) {
      return null;
    }

    final orderId = orderResults.first['id'] as int;
    return getOrderById(orderId);
  }

  /// Get payment information for an order
  Future<Payment?> getPaymentByOrderId(int orderId) async {
    final db = await _database.database;

    final results = await db.query(
      'payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    if (results.isEmpty) {
      return null;
    }

    return Payment.fromJson(results.first);
  }

  /// Get the latest order for a user (most recent)
  Future<Order?> getLatestOrderForUser(int userId) async {
    final db = await _database.database;

    final orderResults = await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'placed_at DESC',
      limit: 1,
    );

    if (orderResults.isEmpty) {
      return null;
    }

    final orderId = orderResults.first['id'] as int;
    return getOrderById(orderId);
  }

  /// Calculate estimated delivery date (current date + 3-5 days)
  DateTime calculateEstimatedDelivery(DateTime orderDate) {
    // Add 4 days as average delivery time
    return orderDate.add(const Duration(days: 4));
  }

  /// Format date for display (e.g., "Oct 24, 2023")
  String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Get masked card number from payment method
  String getMaskedCardNumber(String? transactionRef) {
    if (transactionRef == null || transactionRef.isEmpty) {
      return '';
    }
    
    // Extract last 4 digits from transaction ref if available
    if (transactionRef.length >= 4) {
      final lastFour = transactionRef.substring(transactionRef.length - 4);
      return 'ending in $lastFour';
    }
    
    return '';
  }

  /// Get payment method display text
  String getPaymentMethodDisplay(String method, String? cardInfo) {
    switch (method.toLowerCase()) {
      case 'card':
      case 'credit_card':
        return cardInfo != null && cardInfo.isNotEmpty 
            ? 'Visa $cardInfo' 
            : 'Credit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cash':
      case 'cod':
        return 'Cash on Delivery';
      default:
        return method;
    }
  }
}
