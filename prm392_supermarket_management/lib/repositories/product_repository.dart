import 'package:sqflite/sqflite.dart';
import '../data/app_database.dart';
import '../models/product.dart';

class ProductRepository {
  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  ProductRepository._internal();

  // Get database instance
  Future<Database> get _database async {
    return await AppDatabase.instance.database;
  }

  // Create product
  Future<int> createProduct(Product product) async {
    final db = await _database;
    final productMap = product.toMap();
    productMap.remove('id'); // Remove id for auto-increment
    return await db.insert('products', productMap);
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    final db = await _database;
    final result = await db.query(
      'products',
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Get active products only
  Future<List<Product>> getActiveProducts() async {
    final db = await _database;
    final result = await db.query(
      'products',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Get product by ID
  Future<Product?> getProductById(int id) async {
    final db = await _database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await _database;
    final result = await db.query(
      'products',
      where: 'category_id = ? AND is_active = ?',
      whereArgs: [categoryId, 1],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Search products by name or description
  Future<List<Product>> searchProducts(String query) async {
    final db = await _database;
    final result = await db.query(
      'products',
      where: '(name LIKE ? OR description LIKE ?) AND is_active = ?',
      whereArgs: ['%$query%', '%$query%', 1],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Get products by SKU
  Future<Product?> getProductBySku(String sku) async {
    final db = await _database;
    final result = await db.query(
      'products',
      where: 'sku = ?',
      whereArgs: [sku],
    );
    
    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts({int threshold = 5}) async {
    final db = await _database;
    final result = await db.query(
      'products',
      where: 'stock_quantity <= ? AND stock_quantity > 0 AND is_active = ?',
      whereArgs: [threshold, 1],
      orderBy: 'stock_quantity ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Get out of stock products
  Future<List<Product>> getOutOfStockProducts() async {
    final db = await _database;
    final result = await db.query(
      'products',
      where: 'stock_quantity = 0 AND is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Update product
  Future<int> updateProduct(Product product) async {
    final db = await _database;
    final updatedProduct = product.copyWith(
      updatedAt: DateTime.now(),
    );
    return await db.update(
      'products',
      updatedProduct.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Update stock quantity
  Future<int> updateStock(int productId, int newQuantity) async {
    final db = await _database;
    return await db.update(
      'products',
      {
        'stock_quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Decrease stock (when product is sold)
  Future<bool> decreaseStock(int productId, int quantity) async {
    // First check current stock
    final product = await getProductById(productId);
    if (product == null || product.stockQuantity < quantity) {
      return false; // Not enough stock
    }
    
    final newQuantity = product.stockQuantity - quantity;
    await updateStock(productId, newQuantity);
    return true;
  }

  // Increase stock (when restocking)
  Future<int> increaseStock(int productId, int quantity) async {
    final product = await getProductById(productId);
    if (product == null) {
      throw Exception('Product not found');
    }
    
    final newQuantity = product.stockQuantity + quantity;
    return await updateStock(productId, newQuantity);
  }

  // Deactivate product (soft delete)
  Future<int> deactivateProduct(int productId) async {
    final db = await _database;
    return await db.update(
      'products',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Activate product
  Future<int> activateProduct(int productId) async {
    final db = await _database;
    return await db.update(
      'products',
      {
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Delete product permanently
  Future<int> deleteProduct(int productId) async {
    final db = await _database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Get product statistics
  Future<Map<String, int>> getProductStats() async {
    final db = await _database;
    
    final totalProducts = await db.rawQuery('SELECT COUNT(*) as count FROM products WHERE is_active = 1');
    final outOfStock = await db.rawQuery('SELECT COUNT(*) as count FROM products WHERE stock_quantity = 0 AND is_active = 1');
    final lowStock = await db.rawQuery('SELECT COUNT(*) as count FROM products WHERE stock_quantity <= 5 AND stock_quantity > 0 AND is_active = 1');
    
    return {
      'total': totalProducts.first['count'] as int,
      'outOfStock': outOfStock.first['count'] as int,
      'lowStock': lowStock.first['count'] as int,
    };
  }

  // Get products with pagination
  Future<List<Product>> getProductsPaginated({
    int page = 0,
    int pageSize = 20,
    int? categoryId,
    String? searchQuery,
  }) async {
    final db = await _database;
    final offset = page * pageSize;
    
    String whereClause = 'is_active = ?';
    List<dynamic> whereArgs = [1];
    
    if (categoryId != null) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR description LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }
    
    final result = await db.query(
      'products',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: pageSize,
      offset: offset,
    );
    
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Check if SKU is unique
  Future<bool> isSkuUnique(String sku, {int? excludeProductId}) async {
    final db = await _database;
    String whereClause = 'sku = ?';
    List<dynamic> whereArgs = [sku];
    
    if (excludeProductId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeProductId);
    }
    
    final result = await db.query(
      'products',
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    return result.isEmpty;
  }
}