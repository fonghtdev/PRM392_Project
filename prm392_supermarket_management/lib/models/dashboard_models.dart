enum OrderStatus { paid, pending, cancelled }

class DashboardMetric {
  final String title;
  final String value;
  final String percentage;
  final String iconName;
  final bool isPositive;

  const DashboardMetric({
    required this.title,
    required this.value,
    required this.percentage,
    required this.iconName,
    required this.isPositive,
  });
}

class Order {
  final String id;
  final String customerName;
  final String customerEmail;
  final double totalAmount;
  final OrderStatus status;
  final DateTime orderTime;
  final int itemCount;

  const Order({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.totalAmount,
    required this.status,
    required this.orderTime,
    required this.itemCount,
  });

  String get formattedPrice => '\$${totalAmount.toStringAsFixed(2)}';
  
  String get statusText {
    switch (status) {
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
  
  String get itemsText => '$itemCount item${itemCount > 1 ? 's' : ''}';
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(orderTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }
}

class SalesData {
  final String revenue;
  final String period;
  final List<double> chartData;

  const SalesData({
    required this.revenue,
    required this.period,
    required this.chartData,
  });
}