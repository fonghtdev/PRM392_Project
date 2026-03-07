import '../data/app_database.dart';
import '../models/cart_item.dart';
import '../models/suggested_product.dart';

class CartService {
  final AppDatabase _db = AppDatabase.instance;

  // Get cart items from database for a specific user
  Future<List<CartItem>> getCartItems(int userId) async {
    final database = await _db.database;
    
    // Join cart_items with products to get full product information
    final results = await database.rawQuery('''
      SELECT 
        ci.id,
        ci.quantity,
        p.id as product_id,
        p.name,
        p.description,
        p.price,
        p.image_url,
        c.name as category_name
      FROM cart_items ci
      INNER JOIN products p ON ci.product_id = p.id
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE ci.user_id = ? AND p.is_active = 1
      ORDER BY ci.added_at DESC
    ''', [userId]);

    return results.map((row) {
      return CartItem(
        id: row['product_id'] as int,
        name: row['name'] as String,
        variant: row['category_name'] as String? ?? 'General',
        price: row['price'] as double,
        imageUrl: row['image_url'] as String? ?? '',
        quantity: row['quantity'] as int,
      );
    }).toList();
  }

  // Get suggested products from database (random products not in cart)
  Future<List<SuggestedProduct>> getSuggestedProducts(int userId, {int limit = 5}) async {
    final database = await _db.database;
    
    final results = await database.rawQuery('''
      SELECT 
        p.id,
        p.name,
        p.price,
        p.image_url
      FROM products p
      WHERE p.is_active = 1 
        AND p.stock_quantity > 0
        AND p.id NOT IN (
          SELECT product_id FROM cart_items WHERE user_id = ?
        )
      ORDER BY RANDOM()
      LIMIT ?
    ''', [userId, limit]);

    return results.map((row) {
      return SuggestedProduct(
        id: row['id'] as int,
        name: row['name'] as String,
        price: row['price'] as double,
        imageUrl: row['image_url'] as String? ?? '',
      );
    }).toList();
  }

  // Calculate shipping fee threshold
  double getShippingFeeThreshold() {
    return 200.00; // Free shipping at $200
  }

  // Calculate shipping fee
  double calculateShippingFee(double subtotal) {
    if (subtotal >= getShippingFeeThreshold()) {
      return 0.00;
    }
    return 15.00;
  }

  // Update item quantity in database
  Future<void> updateQuantity(int userId, int productId, int newQuantity) async {
    final database = await _db.database;
    
    if (newQuantity <= 0) {
      // If quantity is 0 or less, remove the item
      await removeItem(userId, productId);
      return;
    }

    await database.update(
      'cart_items',
      {'quantity': newQuantity},
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );
  }

  // Remove item from cart in database
  Future<void> removeItem(int userId, int productId) async {
    final database = await _db.database;
    
    await database.delete(
      'cart_items',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );
  }

  // Add item to cart
  Future<void> addToCart(int userId, int productId, int quantity) async {
    final database = await _db.database;
    
    // Check if item already exists in cart
    final existing = await database.query(
      'cart_items',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );

    if (existing.isNotEmpty) {
      // Update quantity
      final currentQuantity = existing.first['quantity'] as int;
      await database.update(
        'cart_items',
        {'quantity': currentQuantity + quantity},
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
      );
    } else {
      // Insert new item
      await database.insert('cart_items', {
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
      });
    }
  }

  // Clear cart for user
  Future<void> clearCart(int userId) async {
    final database = await _db.database;
    
    await database.delete(
      'cart_items',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Get cart item count for user
  Future<int> getCartItemCount(int userId) async {
    final database = await _db.database;
    
    final result = await database.rawQuery('''
      SELECT SUM(quantity) as total
      FROM cart_items
      WHERE user_id = ?
    ''', [userId]);

    return (result.first['total'] as int?) ?? 0;
  }
}
