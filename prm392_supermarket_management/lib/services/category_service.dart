import '../models/category.dart';
import '../data/app_database.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  // Get all categories
  Future<List<Category>> getAllCategories() async {
    try {
      final db = await AppDatabase.instance.database;
      final maps = await db.query(
        'categories',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return maps.map((map) => Category.fromMap(map)).toList();
    } catch (e) {
      print('Error in CategoryService.getAllCategories: $e');
      return [];
    }
  }

  // Get category by ID
  Future<Category?> getCategoryById(int id) async {
    try {
      final db = await AppDatabase.instance.database;
      final maps = await db.query(
        'categories',
        where: 'id = ? AND is_active = ?',
        whereArgs: [id, 1],
      );
      if (maps.isNotEmpty) {
        return Category.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error in CategoryService.getCategoryById: $e');
      return null;
    }
  }

  // Get active categories only
  Future<List<Category>> getActiveCategories() async {
    try {
      return await getAllCategories();
    } catch (e) {
      print('Error in CategoryService.getActiveCategories: $e');
      return [];
    }
  }
}