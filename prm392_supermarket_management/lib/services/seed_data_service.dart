import '../data/app_database.dart';

class SeedDataService {
  static final AppDatabase _database = AppDatabase.instance;

  /// Thêm dữ liệu mẫu cho orders để test dashboard
  static Future<void> addSampleOrders() async {
    final db = await _database.database;
    
    // Kiểm tra xem đã có orders chưa
    final existingOrders = await db.rawQuery('SELECT COUNT(*) as count FROM orders');
    final orderCount = existingOrders.first['count'] as int;
    
    print('🔍 Current orders in database: $orderCount');
    
    if (orderCount > 0) {
      print('✅ Orders already exist, skipping seed');
      return;
    }
    
    // Lấy user_id và product_id từ database
    final users = await db.query('users', where: 'role = ?', whereArgs: ['user']);
    final products = await db.query('products', limit: 5);
    
    if (users.isEmpty || products.isEmpty) {
      print('❌ No users or products found, cannot create orders');
      return;
    }
    
    final userId = users.first['id'] as int;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Thêm nhiều orders mẫu với thời gian khác nhau
    final orders = [
      {
        'user_id': userId,
        'order_code': 'ORD-${timestamp}001',
        'status': 'completed',
        'subtotal': 199.0,
        'shipping_fee': 5.0,
        'total': 204.0,
        'placed_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      },
      {
        'user_id': userId,
        'order_code': 'ORD-${timestamp}002',
        'status': 'pending',
        'subtotal': 145.0,
        'shipping_fee': 10.0,
        'total': 155.0,
        'placed_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      },
      {
        'user_id': userId,
        'order_code': 'ORD-${timestamp}003',
        'status': 'completed',
        'subtotal': 34.0,
        'shipping_fee': 0.0,
        'total': 34.0,
        'placed_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
      {
        'user_id': userId,
        'order_code': 'ORD-${timestamp}004',
        'status': 'delivered',
        'subtotal': 299.0,
        'shipping_fee': 15.0,
        'total': 314.0,
        'placed_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'user_id': userId,
        'order_code': 'ORD-${timestamp}005',
        'status': 'processing',
        'subtotal': 89.0,
        'shipping_fee': 5.0,
        'total': 94.0,
        'placed_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      },
    ];

    for (int i = 0; i < orders.length; i++) {
      final order = orders[i];
      final orderId = await db.insert('orders', order);
      
      // Thêm order items với tên sản phẩm từ database
      final product = products[i % products.length];
      await db.insert('order_items', {
        'order_id': orderId,
        'product_id': product['id'],
        'product_name': product['name'],
        'unit_price': order['subtotal'],
        'quantity': 1,
        'line_total': order['subtotal'],
      });
      
      print('✅ Created order ${order['order_code']} with product ${product['name']}');
    }
    
    print('🎉 Successfully added ${orders.length} sample orders to database');
  }
}