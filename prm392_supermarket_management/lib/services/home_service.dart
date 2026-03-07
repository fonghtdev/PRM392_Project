import '../data/app_database.dart';
import '../models/category.dart';
import '../models/product.dart';

class HomeService {
  final AppDatabase _database = AppDatabase.instance;

  /// Get all active categories
  Future<List<Category>> getCategories() async {
    final db = await _database.database;
    
    final results = await db.query(
      'categories',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return results.map((map) => Category.fromMap(map)).toList();
  }

  /// Get featured products (latest active products)
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    final db = await _database.database;
    
    final results = await db.query(
      'products',
      where: 'is_active = ? AND stock_quantity > ?',
      whereArgs: [1, 0],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return results.map((map) => Product.fromMap(map)).toList();
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(int categoryId, {int limit = 10}) async {
    final db = await _database.database;
    
    final results = await db.query(
      'products',
      where: 'category_id = ? AND is_active = ? AND stock_quantity > ?',
      whereArgs: [categoryId, 1, 0],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return results.map((map) => Product.fromMap(map)).toList();
  }

  /// Search products
  Future<List<Product>> searchProducts(String query) async {
    final db = await _database.database;
    
    final results = await db.query(
      'products',
      where: 'is_active = ? AND (name LIKE ? OR description LIKE ?)',
      whereArgs: [1, '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return results.map((map) => Product.fromMap(map)).toList();
  }

  /// Add product to cart
  Future<void> addToCart(int userId, int productId, {int quantity = 1}) async {
    final db = await _database.database;
    
    // Check if item already exists in cart
    final existing = await db.query(
      'cart_items',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );

    if (existing.isNotEmpty) {
      // Update quantity
      final currentQty = existing.first['quantity'] as int;
      await db.update(
        'cart_items',
        {'quantity': currentQty + quantity},
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
      );
    } else {
      // Insert new item
      await db.insert('cart_items', {
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
        'added_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Toggle product favorite (wishlist)
  Future<void> toggleFavorite(int userId, int productId) async {
    // Check if favorites table exists, if not we'll skip this feature
    // For now, we'll just log it since the database doesn't have a wishlist table
    // In production, you would create a favorites/wishlist table
    
    // Placeholder for future wishlist functionality
  }
}
