import '../models/order.dart';
import '../models/payment.dart';
import '../services/order_success_service.dart';

class OrderSuccessRepository {
  final OrderSuccessService _service = OrderSuccessService();

  /// Get order details by ID
  Future<Order?> getOrderById(int orderId) {
    return _service.getOrderById(orderId);
  }

  /// Get order by order code
  Future<Order?> getOrderByCode(String orderCode) {
    return _service.getOrderByCode(orderCode);
  }

  /// Get payment information for an order
  Future<Payment?> getPaymentByOrderId(int orderId) {
    return _service.getPaymentByOrderId(orderId);
  }

  /// Get the latest order for a user
  Future<Order?> getLatestOrderForUser(int userId) {
    return _service.getLatestOrderForUser(userId);
  }

  /// Calculate estimated delivery date
  DateTime calculateEstimatedDelivery(DateTime orderDate) {
    return _service.calculateEstimatedDelivery(orderDate);
  }

  /// Format date for display
  String formatDate(DateTime date) {
    return _service.formatDate(date);
  }

  /// Get payment method display text
  String getPaymentMethodDisplay(String method, String? cardInfo) {
    return _service.getPaymentMethodDisplay(method, cardInfo);
  }

  /// Get masked card number
  String getMaskedCardNumber(String? transactionRef) {
    return _service.getMaskedCardNumber(transactionRef);
  }
}
