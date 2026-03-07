import '../models/order.dart';
import '../repositories/order_repository.dart';

class OrderService {
  final OrderRepository _orderRepository = OrderRepository();

  // Get all orders with filters
  Future<List<Order>> getOrders({
    int page = 0,
    int limit = 20,
    OrderStatus? status,
    String? searchQuery,
  }) async {
    try {
      final offset = page * limit;
      return await _orderRepository.getOrders(
        limit: limit,
        offset: offset,
        status: status,
        searchQuery: searchQuery,
      );
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  // Get order by ID
  Future<Order?> getOrderById(int id) async {
    try {
      return await _orderRepository.getOrderById(id);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Get orders by user
  Future<List<Order>> getOrdersByUserId(int userId) async {
    try {
      return await _orderRepository.getOrdersByUserId(userId);
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  // Create new order
  Future<int> createOrder(Order order) async {
    try {
      // Validate order
      _validateOrder(order);
      
      return await _orderRepository.createOrder(order);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(int orderId, OrderStatus newStatus) async {
    try {
      // Get current order to validate transition
      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      // Validate status transition
      if (!_canTransitionStatus(order.status, newStatus)) {
        throw Exception('Invalid status transition from ${order.status.value} to ${newStatus.value}');
      }

      await _orderRepository.updateOrderStatus(orderId, newStatus);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Update entire order
  Future<void> updateOrder(Order order) async {
    try {
      _validateOrder(order);
      await _orderRepository.updateOrder(order);
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  // Cancel order
  Future<void> cancelOrder(int orderId) async {
    try {
      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      if (!order.canBeCancelled) {
        throw Exception('Order cannot be cancelled in current status');
      }

      await _orderRepository.updateOrderStatus(orderId, OrderStatus.cancelled);
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Delete order (admin only)
  Future<void> deleteOrder(int orderId) async {
    try {
      await _orderRepository.deleteOrder(orderId);
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  // Get order statistics
  Future<OrderStats> getOrderStats({DateTime? startDate, DateTime? endDate}) async {
    try {
      final stats = await _orderRepository.getOrderStats(
        startDate: startDate,
        endDate: endDate,
      );
      return OrderStats.fromJson(stats);
    } catch (e) {
      throw Exception('Failed to get order stats: $e');
    }
  }

  // Get today's orders
  Future<List<Order>> getTodayOrders() async {
    try {
      return await _orderRepository.getOrders(
        limit: 100,
        offset: 0,
      );
    } catch (e) {
      throw Exception('Failed to get today\'s orders: $e');
    }
  }

  // Get pending orders
  Future<List<Order>> getPendingOrders() async {
    try {
      return await _orderRepository.getOrders(
        status: OrderStatus.pending,
        limit: 50,
      );
    } catch (e) {
      throw Exception('Failed to get pending orders: $e');
    }
  }

  // Search orders
  Future<List<Order>> searchOrders(String query) async {
    try {
      return await _orderRepository.searchOrders(query);
    } catch (e) {
      throw Exception('Failed to search orders: $e');
    }
  }

  // Get recent orders
  Future<List<Order>> getRecentOrders({int limit = 10}) async {
    try {
      return await _orderRepository.getRecentOrders(limit: limit);
    } catch (e) {
      throw Exception('Failed to get recent orders: $e');
    }
  }

  // Private validation methods
  void _validateOrder(Order order) {
    if (order.orderCode.isEmpty) {
      throw Exception('Order code is required');
    }
    
    if (order.total <= 0) {
      throw Exception('Order total must be greater than 0');
    }
    
    if (order.subtotal <= 0) {
      throw Exception('Order subtotal must be greater than 0');
    }
    
    if (order.items?.isEmpty ?? true) {
      throw Exception('Order must have at least one item');
    }

    // Validate order items
    for (final item in order.items!) {
      if (item.quantity <= 0) {
        throw Exception('Order item quantity must be greater than 0');
      }
      if (item.unitPrice < 0) {
        throw Exception('Order item price cannot be negative');
      }
    }
  }

  bool _canTransitionStatus(OrderStatus from, OrderStatus to) {
    // Define valid status transitions
    final validTransitions = {
      OrderStatus.pending: [OrderStatus.confirmed, OrderStatus.cancelled],
      OrderStatus.confirmed: [OrderStatus.processing, OrderStatus.cancelled],
      OrderStatus.processing: [OrderStatus.shipping, OrderStatus.cancelled],
      OrderStatus.shipping: [OrderStatus.delivered],
      OrderStatus.delivered: [OrderStatus.refunded],
      OrderStatus.cancelled: [], // No transitions from cancelled
      OrderStatus.refunded: [], // No transitions from refunded
    };

    return validTransitions[from]?.contains(to) ?? false;
  }

  // Generate order code
  String generateOrderCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ORD-${timestamp.toString().substring(timestamp.toString().length - 8)}';
  }

  // Calculate order total
  double calculateTotal(List<OrderItem> items, double shippingFee) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    return subtotal + shippingFee;
  }
}

// Order statistics class
class OrderStats {
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final int todayOrders;
  final double todayRevenue;
  final Map<String, int> statusBreakdown;

  const OrderStats({
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.todayOrders,
    required this.todayRevenue,
    required this.statusBreakdown,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      totalOrders: json['total_orders'] as int,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      averageOrderValue: (json['average_order_value'] as num).toDouble(),
      todayOrders: json['today_orders'] as int,
      todayRevenue: (json['today_revenue'] as num).toDouble(),
      statusBreakdown: Map<String, int>.from(json['status_breakdown'] as Map),
    );
  }

  String get formattedTotalRevenue => '${totalRevenue.toStringAsFixed(0)}₫';
  String get formattedTodayRevenue => '${todayRevenue.toStringAsFixed(0)}₫';
  String get formattedAverageOrderValue => '${averageOrderValue.toStringAsFixed(0)}₫';
}