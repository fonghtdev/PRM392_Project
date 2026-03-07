class Payment {
  final int? id;
  final int orderId;
  final String method;
  final String status;
  final double paidAmount;
  final DateTime? paidAt;
  final String? transactionRef;

  const Payment({
    this.id,
    required this.orderId,
    required this.method,
    required this.status,
    required this.paidAmount,
    this.paidAt,
    this.transactionRef,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int?,
      orderId: json['order_id'] as int,
      method: json['method'] as String,
      status: json['status'] as String,
      paidAmount: (json['paid_amount'] as num).toDouble(),
      paidAt: json['paid_at'] != null 
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      transactionRef: json['transaction_ref'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'method': method,
      'status': status,
      'paid_amount': paidAmount,
      'paid_at': paidAt?.toIso8601String(),
      'transaction_ref': transactionRef,
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'order_id': orderId,
      'method': method,
      'status': status,
      'paid_amount': paidAmount,
      'paid_at': paidAt?.toIso8601String(),
      'transaction_ref': transactionRef,
    };
  }

  String get formattedAmount => '\$${paidAmount.toStringAsFixed(2)}';
}
