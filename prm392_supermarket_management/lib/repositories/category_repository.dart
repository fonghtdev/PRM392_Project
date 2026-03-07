import 'package:sqflite/sqflite.dart';
import '../data/app_database.dart';
import '../models/category.dart';

class CategoryRepository {
  static final CategoryRepository _instance = CategoryRepository._internal();
  factory CategoryRepository() => _instance;
  CategoryRepository._internal();

  // Get database instance
  Future<Database> get _database async {
    return await AppDatabase.instance.database;
  }

  // Create category
  Future<Category> createCategory(Category category) async {
    final db = await _database;
    final categoryMap = category.toMap();
    categoryMap.remove('id'); // Remove id for auto-increment
    final id = await db.insert('categories', categoryMap);
    
    return category.copyWith(id: id);
  }

  // Get all categories
  Future<List<Category>> getAllCategories() async {
    final db = await _database;
    final result = await db.query(
      'categories',
      orderBy: 'name ASC',
    );
    return result.map((map) => Category.fromMap(map)).toList();
  }

  // Get active categories only
  Future<List<Category>> getActiveCategories() async {
    final db = await _database;
    final result = await db.query(
      'categories',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((map) => Category.fromMap(map)).toList();
  }

  // Get category by ID
  Future<Category?> getCategoryById(int id) async {
    final db = await _database;
    final result = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      return Category.fromMap(result.first);
    }
    return null;
  }

  // Update category
  Future<Category> updateCategory(Category category) async {
    final db = await _database;
    final updatedCategory = category.copyWith(updatedAt: DateTime.now());
    
    await db.update(
      'categories',
      updatedCategory.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    
    return updatedCategory;
  }

  // Delete category (soft delete)
  Future<bool> deleteCategory(int id) async {
    final db = await _database;
    final result = await db.update(
      'categories',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return result > 0;
  }

  // Toggle category active status
  Future<bool> toggleCategoryStatus(int id) async {
    final db = await _database;
    
    // First get current status
    final current = await getCategoryById(id);
    if (current == null) return false;
    
    final result = await db.update(
      'categories',
      {
        'is_active': current.isActive ? 0 : 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return result > 0;
  }

  // Check if category has products
  Future<bool> hasProducts(int categoryId) async {
    final db = await _database;
    final result = await db.query(
      'products',
      where: 'category_id = ? AND is_active = ?',
      whereArgs: [categoryId, 1],
      limit: 1,
    );
    
    return result.isNotEmpty;
  }

  // Get category with product count
  Future<Map<String, dynamic>> getCategoryStats(int categoryId) async {
    final db = await _database;
    
    final category = await getCategoryById(categoryId);
    if (category == null) return {};
    
    // Get product count
    final productCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE category_id = ? AND is_active = ?',
      [categoryId, 1],
    );
    
    // Get total stock
    final stockCount = await db.rawQuery(
      'SELECT SUM(stock_quantity) as total FROM products WHERE category_id = ? AND is_active = ?',
      [categoryId, 1],
    );
    
    return {
      'category': category.toJson(),
      'product_count': productCount.first['count'] ?? 0,
      'total_stock': stockCount.first['total'] ?? 0,
    };
  }

  // Search categories
  Future<List<Category>> searchCategories(String query) async {
    final db = await _database;
    final result = await db.query(
      'categories',
      where: '(name LIKE ? OR description LIKE ?) AND is_active = ?',
      whereArgs: ['%$query%', '%$query%', 1],
      orderBy: 'name ASC',
    );
    
    return result.map((map) => Category.fromMap(map)).toList();
  }

  // Get categories with product count
  Future<List<Map<String, dynamic>>> getCategoriesWithProductCount() async {
    final db = await _database;
    final result = await db.rawQuery('''
      SELECT 
        c.*,
        COUNT(p.id) as product_count
      FROM categories c
      LEFT JOIN products p ON c.id = p.category_id AND p.is_active = 1
      WHERE c.is_active = 1
      GROUP BY c.id
      ORDER BY c.name ASC
    ''');
    
    return result;
  }

  // Check if category name is unique
  Future<bool> isCategoryNameUnique(String name, {int? excludeId}) async {
    final db = await _database;
    String whereClause = 'LOWER(name) = ? AND is_active = ?';
    List<dynamic> whereArgs = [name.toLowerCase(), 1];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final result = await db.query(
      'categories',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );
    
    return result.isEmpty;
  }

  // Get category by name
  Future<Category?> getCategoryByName(String name) async {
    final db = await _database;
    final result = await db.query(
      'categories',
      where: 'LOWER(name) = ? AND is_active = ?',
      whereArgs: [name.toLowerCase(), 1],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return Category.fromMap(result.first);
    }
    return null;
  }
}