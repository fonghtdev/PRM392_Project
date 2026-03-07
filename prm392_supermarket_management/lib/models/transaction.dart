enum TransactionType {
  purchase,
  refund,
  adjustment,
}

enum TransactionStatus {
  pending,
  completed,
  cancelled,
  refunded,
}

class Transaction {
  final int id;
  final int userId;
  final String userFullName;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String description;
  final String? orderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.type,
    required this.status,
    required this.amount,
    required this.description,
    this.orderId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      userFullName: map['user_full_name'] as String? ?? 'Unknown User',
      type: TransactionType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => TransactionType.purchase,
      ),
      status: TransactionStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      orderId: map['order_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_full_name': userFullName,
      'type': type.name,
      'status': status.name,
      'amount': amount,
      'description': description,
      'order_id': orderId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.purchase:
        return 'Purchase';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.refunded:
        return 'Refunded';
    }
  }

  bool get isPositive => type == TransactionType.purchase;
  bool get isNegative => type == TransactionType.refund || type == TransactionType.adjustment;
}