import 'package:sqflite/sqflite.dart';
import '../data/app_database.dart';
import '../models/transaction.dart' as app_transaction;

class TransactionRepository {
  static final TransactionRepository _instance = TransactionRepository._internal();
  factory TransactionRepository() => _instance;
  TransactionRepository._internal();

  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<app_transaction.Transaction>> getAllTransactions() async {
    print('🔍 TransactionRepository: Getting all transactions...');
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT t.*, u.full_name as user_full_name 
        FROM transactions t
        LEFT JOIN users u ON t.user_id = u.id
        ORDER BY t.created_at DESC
      ''');
      
      final transactions = maps.map((map) => app_transaction.Transaction.fromMap(map)).toList();
      print('✅ TransactionRepository: Found ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      print('❌ TransactionRepository: Error getting transactions: $e');
      return [];
    }
  }

  Future<List<app_transaction.Transaction>> getTransactionsByUser(int userId) async {
    print('🔍 TransactionRepository: Getting transactions for user $userId...');
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT t.*, u.full_name as user_full_name 
        FROM transactions t
        LEFT JOIN users u ON t.user_id = u.id
        WHERE t.user_id = ?
        ORDER BY t.created_at DESC
      ''', [userId]);
      
      final transactions = maps.map((map) => app_transaction.Transaction.fromMap(map)).toList();
      print('✅ TransactionRepository: Found ${transactions.length} transactions for user $userId');
      return transactions;
    } catch (e) {
      print('❌ TransactionRepository: Error getting user transactions: $e');
      return [];
    }
  }

  Future<List<app_transaction.Transaction>> getRecentTransactions({int limit = 10}) async {
    print('🔍 TransactionRepository: Getting recent transactions (limit: $limit)...');
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT t.*, u.full_name as user_full_name 
        FROM transactions t
        LEFT JOIN users u ON t.user_id = u.id
        ORDER BY t.created_at DESC
        LIMIT ?
      ''', [limit]);
      
      final transactions = maps.map((map) => app_transaction.Transaction.fromMap(map)).toList();
      print('✅ TransactionRepository: Found ${transactions.length} recent transactions');
      return transactions;
    } catch (e) {
      print('❌ TransactionRepository: Error getting recent transactions: $e');
      return [];
    }
  }

  Future<double> getTotalRevenue() async {
    print('🔍 TransactionRepository: Calculating total revenue...');
    try {
      final db = await _db;
      final result = await db.rawQuery('''
        SELECT SUM(amount) as total 
        FROM transactions 
        WHERE type = 'purchase' AND status = 'completed'
      ''');
      
      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      print('✅ TransactionRepository: Total revenue: \$${total.toStringAsFixed(2)}');
      return total;
    } catch (e) {
      print('❌ TransactionRepository: Error calculating revenue: $e');
      return 0.0;
    }
  }

  Future<int> insertTransaction(app_transaction.Transaction transaction) async {
    print('🔍 TransactionRepository: Inserting transaction...');
    try {
      final db = await _db;
      final Map<String, dynamic> transactionMap = transaction.toMap();
      transactionMap.remove('id'); // Remove ID for insert
      transactionMap.remove('user_full_name'); // Remove joined field
      
      final id = await db.insert('transactions', transactionMap);
      print('✅ TransactionRepository: Transaction inserted with ID: $id');
      return id;
    } catch (e) {
      print('❌ TransactionRepository: Error inserting transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(app_transaction.Transaction transaction) async {
    print('🔍 TransactionRepository: Updating transaction ${transaction.id}...');
    try {
      final db = await _db;
      final Map<String, dynamic> transactionMap = transaction.toMap();
      transactionMap.remove('user_full_name'); // Remove joined field
      
      await db.update(
        'transactions',
        transactionMap,
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
      print('✅ TransactionRepository: Transaction ${transaction.id} updated');
    } catch (e) {
      print('❌ TransactionRepository: Error updating transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(int id) async {
    print('🔍 TransactionRepository: Deleting transaction $id...');
    try {
      final db = await _db;
      await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ TransactionRepository: Transaction $id deleted');
    } catch (e) {
      print('❌ TransactionRepository: Error deleting transaction: $e');
      rethrow;
    }
  }
}