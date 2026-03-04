import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'supermarket_management.db';
  static const _dbVersion = 2;

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
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('admin', 'user')),
        full_name TEXT NOT NULL
      )
    ''');

    await _createCoreCommerceTables(db);
  }

  Future<void> _seedData(Database db) async {
    await db.insert('users', {
      'username': 'admin',
      'password': '1',
      'role': 'admin',
      'full_name': 'Administrator',
    });
    await db.insert('users', {
      'username': 'user',
      'password': '2',
      'role': 'user',
      'full_name': 'Standard User',
    });

    await _seedCatalogData(db);
  }

  Future<void> _createCoreCommerceTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT
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
        'image_url': null,
      },
      {
        'category_id': categoryIdByName('Fashion'),
        'name': 'Minimalist Wrist Watch',
        'sku': 'FASH-WT-001',
        'description': 'Elegant minimalist watch',
        'price': 145.0,
        'stock_quantity': 25,
        'image_url': null,
      },
      {
        'category_id': categoryIdByName('Home'),
        'name': 'Ceramic Breakfast Bowl',
        'sku': 'HOME-KT-001',
        'description': 'Ceramic bowl for daily use',
        'price': 34.0,
        'stock_quantity': 67,
        'image_url': null,
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
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }
}
