import '../data/app_database.dart';
import '../models/order.dart';

class OrderRepository {
  final AppDatabase _database = AppDatabase.instance;

  // Get all orders with pagination
  Future<List<Order>> getOrders({
    int limit = 20,
    int offset = 0,
    OrderStatus? status,
    String? searchQuery,
  }) async {
    final db = await _database.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (status != null) {
      whereClause = 'WHERE o.status = ?';
      whereArgs.add(status.value);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += whereClause.isEmpty ? 'WHERE ' : ' AND ';
      whereClause += '(o.order_code LIKE ? OR u.full_name LIKE ?)';
      whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
    }
    
    final query = '''
      SELECT 
        o.id, o.user_id, o.address_id, o.order_code, o.status, 
        o.subtotal, o.shipping_fee, o.total, o.placed_at, o.updated_at,
        u.full_name as customer_name,
        u.email as customer_email,
        a.line1 as address_line1,
        a.city as address_city
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      LEFT JOIN addresses a ON o.address_id = a.id
      $whereClause
      ORDER BY o.placed_at DESC
      LIMIT ? OFFSET ?
    ''';
    
    whereArgs.addAll([limit, offset]);
    
    final rows = await db.rawQuery(query, whereArgs);
    
    List<Order> orders = [];
    for (final row in rows) {
      final order = Order.fromJson(row);
      // Load order items for each order
      final items = await getOrderItems(order.id!);
      orders.add(order.copyWith(items: items));
    }
    
    return orders;
  }

  // Get order by ID
  Future<Order?> getOrderById(int id) async {
    final db = await _database.database;
    
    final query = '''
      SELECT 
        o.id, o.user_id, o.address_id, o.order_code, o.status, 
        o.subtotal, o.shipping_fee, o.total, o.placed_at, o.updated_at,
        u.full_name as customer_name,
        u.email as customer_email
      FROM orders o
      LEFT JOIN users u ON o.user_id = u.id
      WHERE o.id = ?
    ''';
    
    final rows = await db.rawQuery(query, [id]);
    if (rows.isEmpty) return null;
    
    final order = Order.fromJson(rows.first);
    final items = await getOrderItems(id);
    
    return order.copyWith(items: items);
  }

  // Get orders by user ID
  Future<List<Order>> getOrdersByUserId(int userId) async {
    final db = await _database.database;
    
    final rows = await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'placed_at DESC',
    );
    
    List<Order> orders = [];
    for (final row in rows) {
      final order = Order.fromJson(row);
      final items = await getOrderItems(order.id!);
      orders.add(order.copyWith(items: items));
    }
    
    return orders;
  }

  // Get order items
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    final db = await _database.database;
    
    final rows = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'id',
    );
    
    return rows.map((row) => OrderItem.fromJson(row)).toList();
  }

  // Create new order
  Future<int> createOrder(Order order) async {
    final db = await _database.database;
    
    return await db.transaction((txn) async {
      // Insert order
      final orderId = await txn.insert('orders', order.toDatabase());
      
      // Insert order items
      if (order.items != null) {
        for (final item in order.items!) {
          await txn.insert('order_items', item.copyWith(orderId: orderId).toDatabase());
        }
      }
      
      return orderId;
    });
  }

  // Update order status
  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    final db = await _database.database;
    
    await db.update(
      'orders',
      {
        'status': status.value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // Update entire order
  Future<void> updateOrder(Order order) async {
    final db = await _database.database;
    
    await db.update(
      'orders',
      order.toDatabase(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  // Delete order
  Future<void> deleteOrder(int orderId) async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      // Delete order items first (foreign key constraint)
      await txn.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      
      // Delete order
      await txn.delete(
        'orders',
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStats({DateTime? startDate, DateTime? endDate}) async {
    final db = await _database.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null && endDate != null) {
      whereClause = 'WHERE placed_at BETWEEN ? AND ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }
    
    // Total orders and revenue
    final totalQuery = '''
      SELECT 
        COUNT(*) as total_orders,
        COALESCE(SUM(total), 0) as total_revenue,
        COALESCE(AVG(total), 0) as average_order_value
      FROM orders 
      $whereClause
    ''';
    
    final totalResult = await db.rawQuery(totalQuery, whereArgs);
    
    // Orders by status
    final statusQuery = '''
      SELECT 
        status,
        COUNT(*) as count
      FROM orders 
      $whereClause
      GROUP BY status
    ''';
    
    final statusResult = await db.rawQuery(statusQuery, whereArgs);
    
    // Today's orders
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final todayQuery = '''
      SELECT 
        COUNT(*) as today_orders,
        COALESCE(SUM(total), 0) as today_revenue
      FROM orders 
      WHERE placed_at BETWEEN ? AND ?
    ''';
    
    final todayResult = await db.rawQuery(todayQuery, [
      todayStart.toIso8601String(),
      todayEnd.toIso8601String(),
    ]);
    
    return {
      'total_orders': totalResult.first['total_orders'] ?? 0,
      'total_revenue': (totalResult.first['total_revenue'] as num?)?.toDouble() ?? 0.0,
      'average_order_value': (totalResult.first['average_order_value'] as num?)?.toDouble() ?? 0.0,
      'today_orders': todayResult.first['today_orders'] ?? 0,
      'today_revenue': (todayResult.first['today_revenue'] as num?)?.toDouble() ?? 0.0,
      'status_breakdown': {
        for (final row in statusResult)
          row['status']: row['count']
      },
    };
  }

  // Get recent orders
  Future<List<Order>> getRecentOrders({int limit = 10}) async {
    return getOrders(limit: limit, offset: 0);
  }

  // Search orders
  Future<List<Order>> searchOrders(String query) async {
    return getOrders(searchQuery: query);
  }
}