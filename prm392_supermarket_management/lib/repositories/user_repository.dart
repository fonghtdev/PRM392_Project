import 'package:sqflite/sqflite.dart';
import '../data/app_database.dart';
import '../models/user.dart';

class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  // Get database instance
  Future<Database> get _database async {
    return await AppDatabase.instance.database;
  }

  // Create user
  Future<int> createUser(User user) async {
    final db = await _database;
    final userMap = user.toMap();
    userMap.remove('id'); // Remove id for auto-increment
    return await db.insert('users', userMap);
  }

  // Get all users
  Future<List<User>> getAllUsers() async {
    final db = await _database;
    final result = await db.query(
      'users',
      orderBy: 'created_at DESC',
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  // Get active users only
  Future<List<User>> getActiveUsers() async {
    final db = await _database;
    final result = await db.query(
      'users',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  // Get user by ID
  Future<User?> getUserById(int id) async {
    final db = await _database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // Get user by username
  Future<User?> getUserByUsername(String username) async {
    final db = await _database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    final db = await _database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // Get users by role
  Future<List<User>> getUsersByRole(UserRole role) async {
    try {
      print('🔍 UserRepository: Getting users by role: ${role.value}');
      final db = await _database;
      final result = await db.query(
        'users',
        where: 'role = ? AND is_active = ?',
        whereArgs: [role.value, 1],
        orderBy: 'full_name ASC',
      );
      print('✅ UserRepository: Found ${result.length} users with role ${role.value}');
      if (result.isNotEmpty) {
        print('✅ UserRepository: First result: ${result.first}');
      }
      return result.map((map) => User.fromMap(map)).toList();
    } catch (e) {
      print('❌ UserRepository error: $e');
      rethrow;
    }
  }

  // Search users by name, email, or username
  Future<List<User>> searchUsers(String query) async {
    final db = await _database;
    final result = await db.query(
      'users',
      where: '(full_name LIKE ? OR email LIKE ? OR username LIKE ?) AND is_active = ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', 1],
      orderBy: 'full_name ASC',
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  // Get admins
  Future<List<User>> getAdmins() async {
    return await getUsersByRole(UserRole.admin);
  }

  // Get customers
  Future<List<User>> getCustomers() async {
    return await getUsersByRole(UserRole.user);
  }

  // Update user
  Future<int> updateUser(User user) async {
    final db = await _database;
    final updatedUser = user.copyWith(
      updatedAt: DateTime.now(),
    );
    return await db.update(
      'users',
      updatedUser.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Update user profile
  Future<int> updateUserProfile({
    required int userId,
    String? fullName,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
  }) async {
    final db = await _database;
    final Map<String, dynamic> updateData = {
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (fullName != null) updateData['full_name'] = fullName;
    if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
    if (address != null) updateData['address'] = address;
    if (profileImageUrl != null) updateData['profile_image_url'] = profileImageUrl;
    
    return await db.update(
      'users',
      updateData,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Change user password (you'll need to hash the password)
  Future<int> changePassword(int userId, String hashedPassword) async {
    final db = await _database;
    return await db.update(
      'users',
      {
        'password_hash': hashedPassword,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Activate user
  Future<int> activateUser(int userId) async {
    final db = await _database;
    return await db.update(
      'users',
      {
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Deactivate user (soft delete)
  Future<int> deactivateUser(int userId) async {
    final db = await _database;
    return await db.update(
      'users',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Delete user permanently
  Future<int> deleteUser(int userId) async {
    final db = await _database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Check if username is unique
  Future<bool> isUsernameUnique(String username, {int? excludeUserId}) async {
    final db = await _database;
    String whereClause = 'username = ?';
    List<dynamic> whereArgs = [username];
    
    if (excludeUserId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeUserId);
    }
    
    final result = await db.query(
      'users',
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    return result.isEmpty;
  }

  // Check if email is unique
  Future<bool> isEmailUnique(String email, {int? excludeUserId}) async {
    final db = await _database;
    String whereClause = 'email = ?';
    List<dynamic> whereArgs = [email];
    
    if (excludeUserId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeUserId);
    }
    
    final result = await db.query(
      'users',
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    return result.isEmpty;
  }

  // Get user statistics
  Future<Map<String, int>> getUserStats() async {
    final db = await _database;
    
    final totalUsers = await db.rawQuery('SELECT COUNT(*) as count FROM users WHERE is_active = 1');
    final totalAdmins = await db.rawQuery('SELECT COUNT(*) as count FROM users WHERE role = ? AND is_active = 1', ['admin']);
    final totalCustomers = await db.rawQuery('SELECT COUNT(*) as count FROM users WHERE role = ? AND is_active = 1', ['user']);
    final inactiveUsers = await db.rawQuery('SELECT COUNT(*) as count FROM users WHERE is_active = 0');
    
    return {
      'total': totalUsers.first['count'] as int,
      'admins': totalAdmins.first['count'] as int,
      'customers': totalCustomers.first['count'] as int,
      'inactive': inactiveUsers.first['count'] as int,
    };
  }

  // Get users with pagination
  Future<List<User>> getUsersPaginated({
    int page = 0,
    int pageSize = 20,
    UserRole? role,
    String? searchQuery,
    bool activeOnly = true,
  }) async {
    final db = await _database;
    final offset = page * pageSize;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (activeOnly) {
      whereClause = 'is_active = ?';
      whereArgs.add(1);
    }
    
    if (role != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'role = ?';
      whereArgs.add(role.value);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(full_name LIKE ? OR email LIKE ? OR username LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }
    
    final result = await db.query(
      'users',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
      limit: pageSize,
      offset: offset,
    );
    
    return result.map((map) => User.fromMap(map)).toList();
  }

  // Get recently registered users
  Future<List<User>> getRecentUsers({int limit = 10}) async {
    final db = await _database;
    final result = await db.query(
      'users',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  // Update last login time
  Future<int> updateLastLogin(int userId) async {
    final db = await _database;
    return await db.update(
      'users',
      {
        'last_login_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Get users by registration date range
  Future<List<User>> getUsersByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _database;
    final result = await db.query(
      'users',
      where: 'created_at BETWEEN ? AND ? AND is_active = ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String(), 1],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  // Batch operations
  Future<int> createMultipleUsers(List<User> users) async {
    final db = await _database;
    int successCount = 0;
    
    await db.transaction((txn) async {
      for (final user in users) {
        try {
          final userMap = user.toMap();
          userMap.remove('id');
          await txn.insert('users', userMap);
          successCount++;
        } catch (e) {
          print('Error creating user ${user.username}: $e');
        }
      }
    });
    
    return successCount;
  }

  // Update multiple users' role
  Future<int> updateUsersRole(List<int> userIds, UserRole newRole) async {
    final db = await _database;
    int successCount = 0;
    
    await db.transaction((txn) async {
      for (final userId in userIds) {
        try {
          await txn.update(
            'users',
            {
              'role': newRole.value,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [userId],
          );
          successCount++;
        } catch (e) {
          print('Error updating user role for ID $userId: $e');
        }
      }
    });
    
    return successCount;
  }

  // TODO: User preferences feature to be implemented later
  // Future<UserPreferences?> getUserPreferences(int userId) async { ... }
  // Future<int> updateUserPreferences(int userId, UserPreferences preferences) async { ... }
}