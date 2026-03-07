import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  final TransactionRepository _repository = TransactionRepository();

  Future<List<Transaction>> getAllTransactions() async {
    print('🔍 TransactionService: Getting all transactions...');
    try {
      final transactions = await _repository.getAllTransactions();
      print('✅ TransactionService: Retrieved ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      print('❌ TransactionService: Error getting transactions: $e');
      return [];
    }
  }

  Future<List<Transaction>> getTransactionsByUser(int userId) async {
    print('🔍 TransactionService: Getting transactions for user $userId...');
    try {
      final transactions = await _repository.getTransactionsByUser(userId);
      print('✅ TransactionService: Retrieved ${transactions.length} transactions for user $userId');
      return transactions;
    } catch (e) {
      print('❌ TransactionService: Error getting user transactions: $e');
      return [];
    }
  }

  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    print('🔍 TransactionService: Getting recent transactions...');
    try {
      final transactions = await _repository.getRecentTransactions(limit: limit);
      print('✅ TransactionService: Retrieved ${transactions.length} recent transactions');
      return transactions;
    } catch (e) {
      print('❌ TransactionService: Error getting recent transactions: $e');
      return [];
    }
  }

  Future<double> getTotalRevenue() async {
    print('🔍 TransactionService: Calculating total revenue...');
    try {
      final revenue = await _repository.getTotalRevenue();
      print('✅ TransactionService: Total revenue: \$${revenue.toStringAsFixed(2)}');
      return revenue;
    } catch (e) {
      print('❌ TransactionService: Error calculating revenue: $e');
      return 0.0;
    }
  }

  Future<Transaction?> createTransaction({
    required int userId,
    required TransactionType type,
    required double amount,
    required String description,
    String? orderId,
  }) async {
    print('🔍 TransactionService: Creating transaction for user $userId...');
    try {
      final transaction = Transaction(
        id: 0, // Will be assigned by database
        userId: userId,
        userFullName: '', // Will be populated by repository join
        type: type,
        status: TransactionStatus.pending,
        amount: amount,
        description: description,
        orderId: orderId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await _repository.insertTransaction(transaction);
      print('✅ TransactionService: Transaction created with ID: $id');
      
      // Return the created transaction with proper ID
      return Transaction(
        id: id,
        userId: transaction.userId,
        userFullName: transaction.userFullName,
        type: transaction.type,
        status: transaction.status,
        amount: transaction.amount,
        description: transaction.description,
        orderId: transaction.orderId,
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt,
      );
    } catch (e) {
      print('❌ TransactionService: Error creating transaction: $e');
      return null;
    }
  }

  Future<bool> updateTransactionStatus(int transactionId, TransactionStatus newStatus) async {
    print('🔍 TransactionService: Updating transaction $transactionId status to ${newStatus.name}...');
    try {
      // First get the transaction
      final transactions = await _repository.getAllTransactions();
      final transaction = transactions.where((t) => t.id == transactionId).firstOrNull;
      
      if (transaction == null) {
        print('❌ TransactionService: Transaction $transactionId not found');
        return false;
      }

      // Update status
      final updatedTransaction = Transaction(
        id: transaction.id,
        userId: transaction.userId,
        userFullName: transaction.userFullName,
        type: transaction.type,
        status: newStatus,
        amount: transaction.amount,
        description: transaction.description,
        orderId: transaction.orderId,
        createdAt: transaction.createdAt,
        updatedAt: DateTime.now(),
      );

      await _repository.updateTransaction(updatedTransaction);
      print('✅ TransactionService: Transaction $transactionId status updated to ${newStatus.name}');
      return true;
    } catch (e) {
      print('❌ TransactionService: Error updating transaction status: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(int transactionId) async {
    print('🔍 TransactionService: Deleting transaction $transactionId...');
    try {
      await _repository.deleteTransaction(transactionId);
      print('✅ TransactionService: Transaction $transactionId deleted');
      return true;
    } catch (e) {
      print('❌ TransactionService: Error deleting transaction: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getTransactionStatistics() async {
    print('🔍 TransactionService: Generating transaction statistics...');
    try {
      final allTransactions = await _repository.getAllTransactions();
      
      final totalTransactions = allTransactions.length;
      final completedTransactions = allTransactions.where((t) => t.status == TransactionStatus.completed).length;
      final pendingTransactions = allTransactions.where((t) => t.status == TransactionStatus.pending).length;
      final totalRevenue = await _repository.getTotalRevenue();
      
      final stats = {
        'total_transactions': totalTransactions,
        'completed_transactions': completedTransactions,
        'pending_transactions': pendingTransactions,
        'total_revenue': totalRevenue,
        'completion_rate': totalTransactions > 0 ? (completedTransactions / totalTransactions * 100) : 0.0,
      };
      
      print('✅ TransactionService: Statistics generated - Total: $totalTransactions, Revenue: \$${totalRevenue.toStringAsFixed(2)}');
      return stats;
    } catch (e) {
      print('❌ TransactionService: Error generating statistics: $e');
      return {};
    }
  }
}