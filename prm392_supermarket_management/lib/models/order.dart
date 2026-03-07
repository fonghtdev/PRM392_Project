class Order {
  final int? id;
  final int userId;
  final int? addressId;
  final String orderCode;
  final OrderStatus status;
  final double subtotal;
  final double shippingFee;
  final double total;
  final DateTime placedAt;
  final DateTime? updatedAt;
  final List<OrderItem>? items;

  const Order({
    this.id,
    required this.userId,
    this.addressId,
    required this.orderCode,
    required this.status,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.placedAt,
    this.updatedAt,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      addressId: json['address_id'] as int?,
      orderCode: json['order_code'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      subtotal: (json['subtotal'] as num).toDouble(),
      shippingFee: (json['shipping_fee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      placedAt: DateTime.parse(json['placed_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'address_id': addressId,
      'order_code': orderCode,
      'status': status.value,
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'total': total,
      'placed_at': placedAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (items != null) 'items': items!.map((item) => item.toJson()).toList(),
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'address_id': addressId,
      'order_code': orderCode,
      'status': status.value,
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'total': total,
      'placed_at': placedAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  Order copyWith({
    int? id,
    int? userId,
    int? addressId,
    String? orderCode,
    OrderStatus? status,
    double? subtotal,
    double? shippingFee,
    double? total,
    DateTime? placedAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      addressId: addressId ?? this.addressId,
      orderCode: orderCode ?? this.orderCode,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      total: total ?? this.total,
      placedAt: placedAt ?? this.placedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  // Helper getters
  String get formattedTotal => '${total.toStringAsFixed(0)}₫';
  String get formattedSubtotal => '${subtotal.toStringAsFixed(0)}₫';
  String get formattedShippingFee => '${shippingFee.toStringAsFixed(0)}₫';
  String get statusDisplayName => status.displayName;
  String get formattedPlacedAt => '${placedAt.day}/${placedAt.month}/${placedAt.year}';
  
  int get totalItems => items?.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;
  
  bool get canBeCancelled => status == OrderStatus.pending || status == OrderStatus.confirmed;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;

  @override
  String toString() {
    return 'Order{id: $id, orderCode: $orderCode, status: $status, total: $total}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int?,
      orderId: json['order_id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      lineTotal: (json['line_total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'line_total': lineTotal,
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'line_total': lineTotal,
    };
  }

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    double? lineTotal,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  // Helper getters
  String get formattedUnitPrice => '${unitPrice.toStringAsFixed(0)}₫';
  String get formattedLineTotal => '${lineTotal.toStringAsFixed(0)}₫';

  @override
  String toString() {
    return 'OrderItem{id: $id, productName: $productName, quantity: $quantity, total: $lineTotal}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum OrderStatus {
  pending('pending', 'Chờ xử lý', '🕒'),
  confirmed('confirmed', 'Đã xác nhận', '✅'),
  processing('processing', 'Đang chuẩn bị', '📦'),
  shipping('shipping', 'Đang giao hàng', '🚚'),
  delivered('delivered', 'Đã giao hàng', '📫'),
  cancelled('cancelled', 'Đã hủy', '❌'),
  refunded('refunded', 'Đã hoàn tiền', '💰');

  const OrderStatus(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static OrderStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipping':
        return OrderStatus.shipping;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }

  static List<OrderStatus> get allStatuses => OrderStatus.values;
  
  static List<OrderStatus> get activeStatuses => [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.shipping,
  ];

  bool get isActive => activeStatuses.contains(this);
  bool get isFinal => this == OrderStatus.delivered || this == OrderStatus.cancelled || this == OrderStatus.refunded;

  @override
  String toString() => displayName;
}