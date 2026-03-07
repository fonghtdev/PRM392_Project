import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'supermarket_management.db';
  static const _dbVersion = 9;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = '$path/$_dbName';

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCoreCommerceTables(db);
          await _seedCatalogData(db);
        }
        if (oldVersion < 3) {
          await _upgradeUsersTable(db);
        }
        if (oldVersion < 4) {
          await _seedDefaultUsers(db);
        }
        if (oldVersion < 5) {
          await _createTransactionsTable(db);
          await _seedTransactionData(db);
        }
        if (oldVersion < 6) {
          await _seedCartItems(db);
        }
        if (oldVersion < 7) {
          await _seedAddresses(db);
        }
        if (oldVersion < 8) {
          // Add missing columns to categories table
          await _upgradeCategoriesTable(db);
        }
        if (oldVersion < 9) {
          // Add payment methods and saved cards tables
          await _createPaymentTables(db);
          await _seedPaymentData(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT,
        full_name TEXT NOT NULL,
        phone_number TEXT,
        address TEXT,
        role TEXT NOT NULL DEFAULT 'user' CHECK(role IN ('admin', 'user', 'moderator')),
        is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
        profile_image_url TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        last_login_at TEXT
      )
    ''');

    // Create user preferences table
    await db.execute('''
      CREATE TABLE user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        dark_mode INTEGER NOT NULL DEFAULT 0 CHECK(dark_mode IN (0, 1)),
        language TEXT NOT NULL DEFAULT 'vi',
        notifications INTEGER NOT NULL DEFAULT 1 CHECK(notifications IN (0, 1)),
        email_notifications INTEGER NOT NULL DEFAULT 1 CHECK(email_notifications IN (0, 1)),
        sms_notifications INTEGER NOT NULL DEFAULT 0 CHECK(sms_notifications IN (0, 1)),
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id),
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await _createCoreCommerceTables(db);
  }

  Future<void> _upgradeUsersTable(Database db) async {
    // Drop old users table and recreate with new structure
    await db.execute('DROP TABLE IF EXISTS users');
    
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT,
        full_name TEXT NOT NULL,
        phone_number TEXT,
        address TEXT,
        role TEXT NOT NULL DEFAULT 'user' CHECK(role IN ('admin', 'user', 'moderator')),
        is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
        profile_image_url TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        last_login_at TEXT
      )
    ''');

    // Create user preferences table if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        dark_mode INTEGER NOT NULL DEFAULT 0 CHECK(dark_mode IN (0, 1)),
        language TEXT NOT NULL DEFAULT 'vi',
        notifications INTEGER NOT NULL DEFAULT 1 CHECK(notifications IN (0, 1)),
        email_notifications INTEGER NOT NULL DEFAULT 1 CHECK(email_notifications IN (0, 1)),
        sms_notifications INTEGER NOT NULL DEFAULT 0 CHECK(sms_notifications IN (0, 1)),
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id),
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Re-seed default users
    await _seedDefaultUsers(db);
  }

  Future<void> _upgradeCategoriesTable(Database db) async {
    // Add missing columns to categories table
    try {
      // Check if columns already exist
      final result = await db.rawQuery('PRAGMA table_info(categories)');
      final columnNames = result.map((row) => row['name'] as String).toSet();
      
      if (!columnNames.contains('icon_url')) {
        await db.execute('ALTER TABLE categories ADD COLUMN icon_url TEXT');
      }
      if (!columnNames.contains('is_active')) {
        await db.execute('ALTER TABLE categories ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1))');
      }
      if (!columnNames.contains('created_at')) {
        await db.execute('ALTER TABLE categories ADD COLUMN created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP');
      }
      if (!columnNames.contains('updated_at')) {
        await db.execute('ALTER TABLE categories ADD COLUMN updated_at TEXT');
      }
      
      print('✅ Categories table upgraded successfully');
    } catch (e) {
      print('❌ Error upgrading categories table: $e');
    }
  }

  Future<void> _seedData(Database db) async {
    // Use the new _seedDefaultUsers method instead
    await _seedDefaultUsers(db);
    await _seedCatalogData(db);
    await _seedSampleOrders(db);
    await _seedCartItems(db);
  }

  Future<void> _createCoreCommerceTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        icon_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        sku TEXT NOT NULL UNIQUE,
        description TEXT,
        price REAL NOT NULL CHECK(price >= 0),
        stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK(stock_quantity >= 0),
        image_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        added_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, product_id),
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS addresses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        recipient_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        line1 TEXT NOT NULL,
        line2 TEXT,
        city TEXT NOT NULL,
        state TEXT,
        postal_code TEXT,
        country TEXT NOT NULL DEFAULT 'VN',
        is_default INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1)),
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        address_id INTEGER,
        order_code TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL DEFAULT 'pending',
        subtotal REAL NOT NULL CHECK(subtotal >= 0),
        shipping_fee REAL NOT NULL DEFAULT 0 CHECK(shipping_fee >= 0),
        total REAL NOT NULL CHECK(total >= 0),
        placed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE RESTRICT,
        FOREIGN KEY(address_id) REFERENCES addresses(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL CHECK(unit_price >= 0),
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        line_total REAL NOT NULL CHECK(line_total >= 0),
        FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL UNIQUE,
        method TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        paid_amount REAL NOT NULL CHECK(paid_amount >= 0),
        paid_at TEXT,
        transaction_ref TEXT,
        FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cart_user ON cart_items(user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_order_user ON orders(user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id)',
    );
  }

  Future<void> _seedCatalogData(Database db) async {
    final existing = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories'),
    );
    if ((existing ?? 0) > 0) {
      return;
    }

    final categories = <Map<String, Object?>>[
      {'name': 'Electronics', 'description': 'Devices and accessories'},
      {'name': 'Fashion', 'description': 'Clothes and lifestyle products'},
      {'name': 'Home', 'description': 'Home and kitchen items'},
    ];

    for (final category in categories) {
      await db.insert('categories', category);
    }

    final inserted = await db.query('categories');
    int categoryIdByName(String name) =>
        inserted.firstWhere((row) => row['name'] == name)['id'] as int;

    final products = <Map<String, Object?>>[
      {
        'category_id': categoryIdByName('Electronics'),
        'name': 'Wireless Headphones Pro',
        'sku': 'ELEC-HP-001',
        'description': 'Noise-cancelling wireless headphones',
        'price': 199.0,
        'stock_quantity': 45,
        'image_url': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=200',
      },
      {
        'category_id': categoryIdByName('Fashion'),
        'name': 'Minimalist Wrist Watch',
        'sku': 'FASH-WT-001',
        'description': 'Elegant minimalist watch',
        'price': 145.0,
        'stock_quantity': 25,
        'image_url': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=200',
      },
      {
        'category_id': categoryIdByName('Home'),
        'name': 'Ceramic Breakfast Bowl',
        'sku': 'HOME-KT-001',
        'description': 'Ceramic bowl for daily use',
        'price': 34.0,
        'stock_quantity': 67,
        'image_url': 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=200',
      },
    ];

    for (final product in products) {
      await db.insert('products', product);
    }
  }

  Future<Map<String, Object?>?> authenticateUser({
    required String username,
    required String password,
  }) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [username, password],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<void> _seedDefaultUsers(Database db) async {
    // Create default admin user
    await db.execute('''
      INSERT OR REPLACE INTO users 
      (id, username, email, password_hash, full_name, phone_number, address, role, is_active, profile_image_url, created_at, updated_at, last_login_at) 
      VALUES 
      (1, 'admin', 'admin@supermarket.com', 'admin123', 'Marcus Thompson', '+1 (555) 0123-4567', '123 Admin Street, City, Country', 'admin', 1, null, datetime('now'), datetime('now'), datetime('now'))
    ''');

    // Create default user preferences for admin
    await db.execute('''
      INSERT OR REPLACE INTO user_preferences 
      (user_id, dark_mode, language, notifications, email_notifications, sms_notifications, created_at, updated_at) 
      VALUES 
      (1, 0, 'vi', 1, 1, 0, datetime('now'), datetime('now'))
    ''');

    // Create a sample regular user
    await db.execute('''
      INSERT OR REPLACE INTO users 
      (id, username, email, password_hash, full_name, phone_number, address, role, is_active, profile_image_url, created_at, updated_at, last_login_at) 
      VALUES 
      (2, 'user001', 'user001@gmail.com', 'user123', 'Nguyễn Văn A', '+84 123 456 789', '456 User Street, Hanoi, Vietnam', 'user', 1, null, datetime('now'), datetime('now'), null)
    ''');

    // Create default user preferences for regular user
    await db.execute('''
      INSERT OR REPLACE INTO user_preferences 
      (user_id, dark_mode, language, notifications, email_notifications, sms_notifications, created_at, updated_at) 
      VALUES 
      (2, 0, 'vi', 1, 1, 0, datetime('now'), datetime('now'))
    ''');
  }

  Future<void> _seedSampleOrders(Database db) async {
    // Check if orders already exist
    final existing = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM orders'),
    );
    if ((existing ?? 0) > 0) {
      return;
    }

    // Create sample orders with different statuses
    final sampleOrders = [
      {
        'id': 1,
        'user_id': 2,
        'order_code': 'ORD-84291',
        'status': 'pending',
        'subtotal': 150.0,
        'shipping_fee': 6.40,
        'total': 156.40,
        'placed_at': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 2,
        'user_id': 2,
        'order_code': 'ORD-84290',
        'status': 'pending',
        'subtotal': 89.0,
        'shipping_fee': 0.0,
        'total': 89.0,
        'placed_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 3,
        'user_id': 2,
        'order_code': 'ORD-84289',
        'status': 'processing',
        'subtotal': 400.0,
        'shipping_fee': 12.50,
        'total': 412.50,
        'placed_at': DateTime.now().subtract(const Duration(minutes: 42)).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 4,
        'user_id': 2,
        'order_code': 'ORD-84288',
        'status': 'delivered',
        'subtotal': 200.0,
        'shipping_fee': 10.0,
        'total': 210.0,
        'placed_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    // Insert sample orders
    for (final order in sampleOrders) {
      await db.insert('orders', order);
    }

    // Create sample order items
    final sampleOrderItems = [
      // Order 1 items
      {
        'order_id': 1,
        'product_id': 1,
        'product_name': 'Wireless Headphones Pro',
        'unit_price': 199.0,
        'quantity': 1,
        'line_total': 199.0,
      },
      // Order 2 items
      {
        'order_id': 2,
        'product_id': 2,
        'product_name': 'Minimalist Wrist Watch',
        'unit_price': 145.0,
        'quantity': 1,
        'line_total': 145.0,
      },
      // Order 3 items
      {
        'order_id': 3,
        'product_id': 1,
        'product_name': 'Wireless Headphones Pro',
        'unit_price': 199.0,
        'quantity': 2,
        'line_total': 398.0,
      },
      {
        'order_id': 3,
        'product_id': 3,
        'product_name': 'Ceramic Breakfast Bowl',
        'unit_price': 34.0,
        'quantity': 1,
        'line_total': 34.0,
      },
      // Order 4 items
      {
        'order_id': 4,
        'product_id': 2,
        'product_name': 'Minimalist Wrist Watch',
        'unit_price': 145.0,
        'quantity': 1,
        'line_total': 145.0,
      },
      {
        'order_id': 4,
        'product_id': 3,
        'product_name': 'Ceramic Breakfast Bowl',
        'unit_price': 34.0,
        'quantity': 2,
        'line_total': 68.0,
      },
    ];

    // Insert sample order items
    for (final item in sampleOrderItems) {
      await db.insert('order_items', item);
    }
  }

  Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('purchase', 'refund', 'adjustment')),
        status TEXT NOT NULL CHECK(status IN ('pending', 'completed', 'cancelled', 'refunded')),
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        order_id TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _seedTransactionData(Database db) async {
    final sampleTransactions = [
      {
        'user_id': 2, // Customer user
        'type': 'purchase',
        'status': 'completed',
        'amount': 125.50,
        'description': 'Purchase of groceries - Order #ORD001',
        'order_id': 'ORD001',
        'created_at': '2026-03-06 09:30:00',
        'updated_at': '2026-03-06 09:35:00',
      },
      {
        'user_id': 2,
        'type': 'purchase',
        'status': 'completed',
        'amount': 89.99,
        'description': 'Electronics purchase - Order #ORD002',
        'order_id': 'ORD002',
        'created_at': '2026-03-05 14:20:00',
        'updated_at': '2026-03-05 14:25:00',
      },
      {
        'user_id': 2,
        'type': 'refund',
        'status': 'completed',
        'amount': 25.00,
        'description': 'Refund for damaged item - Order #ORD001',
        'order_id': 'ORD001',
        'created_at': '2026-03-04 16:45:00',
        'updated_at': '2026-03-04 16:50:00',
      },
      {
        'user_id': 1, // Admin user
        'type': 'adjustment',
        'status': 'completed',
        'amount': 15.00,
        'description': 'Price adjustment for bulk purchase',
        'order_id': null,
        'created_at': '2026-03-03 11:15:00',
        'updated_at': '2026-03-03 11:20:00',
      },
      {
        'user_id': 2,
        'type': 'purchase',
        'status': 'pending',
        'amount': 67.75,
        'description': 'Pending payment - Order #ORD003',
        'order_id': 'ORD003',
        'created_at': '2026-03-02 18:30:00',
        'updated_at': '2026-03-02 18:30:00',
      },
    ];

    // Insert sample transactions
    for (final transaction in sampleTransactions) {
      await db.insert('transactions', transaction);
    }
  }

  Future<void> _seedCartItems(Database db) async {
    // Check if cart items already exist
    final existing = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cart_items'),
    );
    if ((existing ?? 0) > 0) {
      return;
    }

    // Add sample cart items (chỉ dùng product_id 1, 2, 3 vì chỉ có 3 products)
    final sampleCartItems = [
      {
        'user_id': 1,
        'product_id': 1, // Wireless Headphones Pro
        'quantity': 2,
      },
      {
        'user_id': 1,
        'product_id': 2, // Minimalist Wrist Watch
        'quantity': 1,
      },
      {
        'user_id': 1,
        'product_id': 3, // Ceramic Breakfast Bowl
        'quantity': 3,
      },
    ];

    for (final item in sampleCartItems) {
      await db.insert('cart_items', item);
    }
  }

  Future<void> _seedAddresses(Database db) async {
    // Check if addresses already exist
    final existing = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM addresses'),
    );
    if ((existing ?? 0) > 0) {
      return;
    }

    // Add sample addresses for user ID 1
    final sampleAddresses = [
      {
        'user_id': 1,
        'recipient_name': 'Nguyễn Văn A',
        'phone': '+84 123 456 789',
        'line1': '123 Đường Lê Lợi',
        'line2': 'Phường Bến Nghé',
        'city': 'Ho Chi Minh',
        'state': 'Quận 1',
        'postal_code': '70000',
        'country': 'VN',
        'is_default': 1,
        'created_at': '2026-02-01 10:00:00',
      },
      {
        'user_id': 1,
        'recipient_name': 'Nguyễn Văn A (Văn phòng)',
        'phone': '+84 987 654 321',
        'line1': '456 Đường Nguyễn Huệ',
        'line2': 'Tầng 5, Tòa nhà ABC',
        'city': 'Ho Chi Minh',
        'state': 'Quận 1',
        'postal_code': '70000',
        'country': 'VN',
        'is_default': 0,
        'created_at': '2026-02-15 14:30:00',
      },
      {
        'user_id': 1,
        'recipient_name': 'Trần Thị B',
        'phone': '+84 111 222 333',
        'line1': '789 Đường Trần Hưng Đạo',
        'line2': null,
        'city': 'Hanoi',
        'state': 'Hoàn Kiếm',
        'postal_code': '10000',
        'country': 'VN',
        'is_default': 0,
        'created_at': '2026-03-01 09:15:00',
      },
    ];

    for (final address in sampleAddresses) {
      await db.insert('addresses', address);
    }
  }

  Future<void> _createPaymentTables(Database db) async {
    // Create payment_methods table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_methods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL,
        color_class TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create saved_cards table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        card_number TEXT NOT NULL,
        card_holder TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        card_type TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1)),
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Create promo_codes table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS promo_codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        discount_amount REAL NOT NULL CHECK(discount_amount >= 0),
        discount_percent REAL CHECK(discount_percent >= 0 AND discount_percent <= 100),
        min_purchase REAL NOT NULL DEFAULT 0 CHECK(min_purchase >= 0),
        max_discount REAL CHECK(max_discount >= 0),
        valid_from TEXT NOT NULL,
        valid_until TEXT NOT NULL,
        usage_limit INTEGER CHECK(usage_limit > 0),
        usage_count INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_saved_cards_user ON saved_cards(user_id)',
    );
  }

  Future<void> _seedPaymentData(Database db) async {
    // Seed payment methods
    final paymentMethodsExist = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM payment_methods'),
    );
    if ((paymentMethodsExist ?? 0) == 0) {
      final paymentMethods = [
        {
          'id': 'card',
          'name': 'Credit/Debit Card',
          'description': 'Pay securely with your card',
          'icon': 'credit_card',
          'color_class': 'primary',
          'is_active': 1,
        },
        {
          'id': 'bank',
          'name': 'Bank Transfer',
          'description': 'Direct bank transfer',
          'icon': 'account_balance',
          'color_class': 'success',
          'is_active': 1,
        },
        {
          'id': 'cod',
          'name': 'Cash on Delivery',
          'description': 'Pay when you receive',
          'icon': 'local_shipping',
          'color_class': 'warning',
          'is_active': 1,
        },
      ];

      for (final method in paymentMethods) {
        await db.insert('payment_methods', method);
      }
    }

    // Seed saved cards for user 1
    final savedCardsExist = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM saved_cards'),
    );
    if ((savedCardsExist ?? 0) == 0) {
      final savedCards = [
        {
          'user_id': 1,
          'card_number': '4242424242424242',
          'card_holder': 'Marcus Thompson',
          'expiry_date': '12/25',
          'card_type': 'Visa',
          'is_default': 1,
        },
        {
          'user_id': 1,
          'card_number': '5555555555554444',
          'card_holder': 'Marcus Thompson',
          'expiry_date': '08/26',
          'card_type': 'Mastercard',
          'is_default': 0,
        },
        {
          'user_id': 2,
          'card_number': '4111111111111111',
          'card_holder': 'Nguyễn Văn A',
          'expiry_date': '10/27',
          'card_type': 'Visa',
          'is_default': 1,
        },
      ];

      for (final card in savedCards) {
        await db.insert('saved_cards', card);
      }
    }

    // Seed promo codes
    final promoCodesExist = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM promo_codes'),
    );
    if ((promoCodesExist ?? 0) == 0) {
      final promoCodes = [
        {
          'code': 'SAVE10',
          'discount_amount': 42.0,
          'discount_percent': null,
          'min_purchase': 100.0,
          'max_discount': null,
          'valid_from': '2026-01-01 00:00:00',
          'valid_until': '2026-12-31 23:59:59',
          'usage_limit': 100,
          'usage_count': 0,
          'is_active': 1,
        },
        {
          'code': 'WELCOME20',
          'discount_amount': 0.0,
          'discount_percent': 20.0,
          'min_purchase': 50.0,
          'max_discount': 100.0,
          'valid_from': '2026-01-01 00:00:00',
          'valid_until': '2026-12-31 23:59:59',
          'usage_limit': 500,
          'usage_count': 0,
          'is_active': 1,
        },
        {
          'code': 'FREESHIP',
          'discount_amount': 10.0,
          'discount_percent': null,
          'min_purchase': 0.0,
          'max_discount': null,
          'valid_from': '2026-01-01 00:00:00',
          'valid_until': '2026-06-30 23:59:59',
          'usage_limit': 1000,
          'usage_count': 0,
          'is_active': 1,
        },
      ];

      for (final code in promoCodes) {
        await db.insert('promo_codes', code);
      }
    }
  }
}
