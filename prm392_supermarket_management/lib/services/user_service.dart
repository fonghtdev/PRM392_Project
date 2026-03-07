import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final UserRepository _repository = UserRepository();

  // Authentication
  Future<User?> login(String usernameOrEmail, String password) async {
    try {
      User? user;
      
      // Try to find user by email first, then username
      if (usernameOrEmail.contains('@')) {
        user = await _repository.getUserByEmail(usernameOrEmail);
      } else {
        user = await _repository.getUserByUsername(usernameOrEmail);
      }

      if (user == null || !user.isActive) {
        return null;
      }

      // In a real app, you would verify the password hash here
      // For now, we'll assume password verification is successful
      // TODO: Implement proper password verification with bcrypt/argon2
      
      // Update last login time
      await _repository.updateLastLogin(user.id!);
      
      return user;
    } catch (e) {
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  Future<User> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? address,
    UserRole role = UserRole.user,
  }) async {
    // Validate input
    if (username.length < 3) {
      throw Exception('Tên đăng nhập phải có ít nhất 3 ký tự.');
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      throw Exception('Email không hợp lệ.');
    }

    if (password.length < 6) {
      throw Exception('Mật khẩu phải có ít nhất 6 ký tự.');
    }

    if (fullName.trim().isEmpty) {
      throw Exception('Họ tên không được để trống.');
    }

    // Check if username and email are unique
    final isUsernameUnique = await _repository.isUsernameUnique(username);
    if (!isUsernameUnique) {
      throw Exception('Tên đăng nhập đã tồn tại.');
    }

    final isEmailUnique = await _repository.isEmailUnique(email);
    if (!isEmailUnique) {
      throw Exception('Email đã được sử dụng.');
    }

    // Create user
    final user = User(
      username: username.trim().toLowerCase(),
      email: email.trim().toLowerCase(),
      fullName: fullName.trim(),
      phoneNumber: phoneNumber?.trim(),
      address: address?.trim(),
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Hash password (simplified - in production use proper hashing)
    final hashedPassword = _hashPassword(password);
    
    final userId = await _repository.createUser(user);
    // Store password hash separately
    await _repository.changePassword(userId, hashedPassword);
    
    final createdUser = await _repository.getUserById(userId);
    if (createdUser == null) {
      throw Exception('Không thể tạo tài khoản.');
    }

    return createdUser;
  }

  Future<bool> changePassword(int userId, String currentPassword, String newPassword) async {
    if (newPassword.length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự.');
    }

    final user = await _repository.getUserById(userId);
    if (user == null) {
      throw Exception('Không tìm thấy người dùng.');
    }

    // TODO: Verify current password
    // In production, you would verify the current password hash
    
    final hashedPassword = _hashPassword(newPassword);
    final result = await _repository.changePassword(userId, hashedPassword);
    
    return result > 0;
  }

  // Update user information
  Future<bool> updateUser(User user) async {
    try {
      // Validation
      if (user.username.trim().length < 3) {
        throw Exception('Tên đăng nhập phải có ít nhất 3 ký tự.');
      }

      if (!isValidEmail(user.email)) {
        throw Exception('Email không hợp lệ.');
      }

      if (user.fullName.trim().isEmpty) {
        throw Exception('Họ tên không được để trống.');
      }

      // Check if username is taken by another user
      final existingUserByUsername = await _repository.getUserByUsername(user.username);
      if (existingUserByUsername != null && existingUserByUsername.id != user.id) {
        throw Exception('Tên đăng nhập đã tồn tại.');
      }

      // Check if email is taken by another user
      final existingUserByEmail = await _repository.getUserByEmail(user.email);
      if (existingUserByEmail != null && existingUserByEmail.id != user.id) {
        throw Exception('Email đã được sử dụng.');
      }

      final result = await _repository.updateUser(user);
      return result > 0;
    } catch (e) {
      throw Exception('Lỗi cập nhật người dùng: $e');
    }
  }

  // Update user password separately
  Future<bool> updateUserPassword(int userId, String newPassword) async {
    try {
      if (newPassword.length < 6) {
        throw Exception('Mật khẩu phải có ít nhất 6 ký tự.');
      }

      final hashedPassword = _hashPassword(newPassword);
      final result = await _repository.changePassword(userId, hashedPassword);
      
      return result > 0;
    } catch (e) {
      throw Exception('Lỗi cập nhật mật khẩu: $e');
    }
  }

  // User management
  Future<List<User>> getAllUsers() async {
    return await _repository.getAllUsers();
  }

  Future<List<User>> getActiveUsers() async {
    return await _repository.getActiveUsers();
  }

  Future<User?> getUserById(int id) async {
    return await _repository.getUserById(id);
  }

  Future<User?> getUserByUsername(String username) async {
    return await _repository.getUserByUsername(username);
  }

  Future<User?> getUserByEmail(String email) async {
    return await _repository.getUserByEmail(email);
  }

  Future<List<User>> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      return await getActiveUsers();
    }
    return await _repository.searchUsers(query.trim());
  }

  Future<List<User>> getUsersPaginated({
    int page = 0,
    int pageSize = 20,
    UserRole? role,
    String? searchQuery,
    bool activeOnly = true,
  }) async {
    return await _repository.getUsersPaginated(
      page: page,
      pageSize: pageSize,
      role: role,
      searchQuery: searchQuery?.trim(),
      activeOnly: activeOnly,
    );
  }

  // Role management
  Future<List<User>> getAdmins() async {
    return await _repository.getAdmins();
  }

  Future<User?> getCurrentAdmin() async {
    try {
      print('🔍 UserService: Getting admins...');
      final admins = await _repository.getAdmins();
      print('✅ UserService: Found ${admins.length} admins');
      if (admins.isNotEmpty) {
        print('✅ UserService: First admin - ${admins.first.fullName}');
      }
      return admins.isNotEmpty ? admins.first : null;
    } catch (e) {
      print('❌ UserService error: $e');
      throw Exception('Lỗi khi tải thông tin admin: $e');
    }
  }

  Future<List<User>> getCustomers() async {
    return await _repository.getCustomers();
  }

  Future<bool> updateUserRole(int userId, UserRole newRole) async {
    final user = await _repository.getUserById(userId);
    if (user == null) {
      throw Exception('Không tìm thấy người dùng.');
    }

    final updatedUser = user.copyWith(role: newRole);
    final result = await _repository.updateUser(updatedUser);
    
    return result > 0;
  }

  Future<int> bulkUpdateUserRole(List<int> userIds, UserRole newRole) async {
    return await _repository.updateUsersRole(userIds, newRole);
  }

  // Profile management
  Future<User> updateProfile({
    required int userId,
    String? fullName,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
  }) async {
    final user = await _repository.getUserById(userId);
    if (user == null) {
      throw Exception('Không tìm thấy người dùng.');
    }

    // Validate input
    if (fullName != null && fullName.trim().isEmpty) {
      throw Exception('Họ tên không được để trống.');
    }

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      if (!RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phoneNumber)) {
        throw Exception('Số điện thoại không hợp lệ.');
      }
    }

    await _repository.updateUserProfile(
      userId: userId,
      fullName: fullName?.trim(),
      phoneNumber: phoneNumber?.trim(),
      address: address?.trim(),
      profileImageUrl: profileImageUrl?.trim(),
    );

    final updatedUser = await _repository.getUserById(userId);
    if (updatedUser == null) {
      throw Exception('Không thể cập nhật thông tin.');
    }

    return updatedUser;
  }

  // User status management
  Future<bool> activateUser(int userId) async {
    final result = await _repository.activateUser(userId);
    return result > 0;
  }

  Future<bool> deactivateUser(int userId) async {
    final result = await _repository.deactivateUser(userId);
    return result > 0;
  }

  Future<bool> deleteUser(int userId) async {
    final user = await _repository.getUserById(userId);
    if (user == null) {
      throw Exception('Không tìm thấy người dùng.');
    }

    final result = await _repository.deleteUser(userId);
    return result > 0;
  }

  // Statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    final stats = await _repository.getUserStats();
    final recentUsers = await _repository.getRecentUsers(limit: 5);
    
    return {
      'totalUsers': stats['total'],
      'totalAdmins': stats['admins'],
      'totalCustomers': stats['customers'],
      'inactiveUsers': stats['inactive'],
      'recentUsers': recentUsers,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  Future<List<User>> getRecentUsers({int limit = 10}) async {
    return await _repository.getRecentUsers(limit: limit);
  }

  Future<List<User>> getUsersByDateRange(DateTime startDate, DateTime endDate) async {
    return await _repository.getUsersByDateRange(startDate, endDate);
  }

  // TODO: User preferences feature to be implemented later
  // Future<UserPreferences> getUserPreferences(int userId) async { ... }
  // Future<bool> updateUserPreferences(int userId, UserPreferences preferences) async { ... }

  // Validation methods
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isValidUsername(String username) {
    return username.length >= 3 && RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
  }

  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  bool isValidPhoneNumber(String phoneNumber) {
    return RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(phoneNumber);
  }

  Future<bool> isUsernameAvailable(String username, {int? excludeUserId}) async {
    return await _repository.isUsernameUnique(username, excludeUserId: excludeUserId);
  }

  Future<bool> isEmailAvailable(String email, {int? excludeUserId}) async {
    return await _repository.isEmailUnique(email, excludeUserId: excludeUserId);
  }

  // Utility methods
  String generateUsername(String fullName) {
    final words = fullName.trim().toLowerCase().split(' ');
    String username = '';
    
    if (words.isNotEmpty) {
      username = words.first;
      if (words.length > 1) {
        username += words.last.substring(0, 1);
      }
    }
    
    // Remove special characters
    username = username.replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    // Add random number to ensure uniqueness
    final random = Random();
    username += random.nextInt(999).toString().padLeft(3, '0');
    
    return username;
  }

  String _hashPassword(String password) {
    // Simplified password hashing - in production use bcrypt or argon2
    final bytes = utf8.encode(password + 'salt'); // Add salt
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Bulk operations
  Future<int> createMultipleUsers(List<Map<String, dynamic>> usersData) async {
    final List<User> users = [];
    
    for (var userData in usersData) {
      try {
        // Validate each user data
        if (!isValidEmail(userData['email']) || 
            !isValidUsername(userData['username']) ||
            !isValidPassword(userData['password'])) {
          continue;
        }
        
        final user = User(
          username: userData['username'],
          email: userData['email'],
          fullName: userData['fullName'] ?? '',
          phoneNumber: userData['phoneNumber'],
          address: userData['address'],
          role: UserRole.fromString(userData['role'] ?? 'user'),
          isActive: userData['isActive'] ?? true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        users.add(user);
      } catch (e) {
        print('Error processing user data: $e');
      }
    }
    
    return await _repository.createMultipleUsers(users);
  }

  // Admin helpers
  Future<bool> promoteToAdmin(int userId) async {
    return await updateUserRole(userId, UserRole.admin);
  }

  Future<bool> demoteFromAdmin(int userId) async {
    return await updateUserRole(userId, UserRole.user);
  }

  Future<bool> canUserPerformAction(int userId, String action) async {
    final user = await _repository.getUserById(userId);
    if (user == null || !user.isActive) {
      return false;
    }

    switch (action) {
      case 'manage_products':
        return user.role.canManageProducts;
      case 'manage_users':
        return user.role.canManageUsers;
      case 'view_reports':
        return user.role.canViewReports;
      case 'manage_orders':
        return user.role.canManageOrders;
      default:
        return false;
    }
  }

  // User session management
  Future<void> updateLastLogin(int userId) async {
    await _repository.updateLastLogin(userId);
  }

  // Profile completion check
  Future<double> getProfileCompletionPercentage(int userId) async {
    final user = await _repository.getUserById(userId);
    if (user == null) return 0.0;

    int completedFields = 0;
    const int totalFields = 5;

    if (user.fullName.isNotEmpty) completedFields++;
    if (user.email.isNotEmpty) completedFields++;
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) completedFields++;
    if (user.address != null && user.address!.isNotEmpty) completedFields++;
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  // Admin profile specific methods
  Future<void> logout() async {
    // Clear any session data, preferences, etc.
    // In a real app, you might clear SharedPreferences or secure storage
    try {
      // For now, just implement basic logout logic
      // You can extend this to clear any cached user data
      print('Admin logged out');
    } catch (e) {
      throw Exception('Lỗi đăng xuất: $e');
    }
  }

  Future<bool> deleteCurrentAdmin(int adminId) async {
    try {
      final admin = await _repository.getUserById(adminId);
      if (admin == null) {
        throw Exception('Không tìm thấy admin.');
      }

      if (admin.role != UserRole.admin) {
        throw Exception('Người dùng này không phải admin.');
      }

      final result = await _repository.deleteUser(adminId);
      return result > 0;
    } catch (e) {
      throw Exception('Lỗi khi xóa admin: $e');
    }
  }
}