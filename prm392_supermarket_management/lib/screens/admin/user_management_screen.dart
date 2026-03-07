import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../app_bottom_nav.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});
  static const routeName = '/admin/users';

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;
  bool _showStaff = true; // true for staff, false for customers
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterUsers();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreData) {
        _loadMoreUsers();
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users;
        _filterUsers();
      });
    } catch (e) {
      _showErrorSnackBar('Lỗi khi tải danh sách người dùng: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      _currentPage++;
      final newUsers = await _userService.getUsersPaginated(
        page: _currentPage,
        pageSize: _pageSize,
        role: _showStaff ? UserRole.admin : UserRole.user,
        searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
      );
      
      if (newUsers.length < _pageSize) {
        _hasMoreData = false;
      }
      
      setState(() {
        _users.addAll(newUsers);
        _filterUsers();
      });
    } catch (e) {
      _currentPage--;
      _showErrorSnackBar('Lỗi khi tải thêm người dùng: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = _searchController.text.isEmpty ||
            user.fullName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            user.username.toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchesRole = _showStaff 
            ? user.role == UserRole.admin
            : user.role == UserRole.user;
        
        return matchesSearch && matchesRole && user.isActive;
      }).toList();
    });
  }

  void _toggleUserType(bool showStaff) {
    setState(() {
      _showStaff = showStaff;
      _currentPage = 0;
      _hasMoreData = true;
      _filterUsers();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showAddUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddUserDialog(),
    );
    
    if (result == true) {
      _loadUsers();
      _showSuccessSnackBar('Thêm người dùng thành công!');
    }
  }

  Future<void> _showEditUserDialog(User user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    );
    
    if (result == true) {
      _loadUsers();
      _showSuccessSnackBar('Cập nhật người dùng thành công!');
    }
  }

  Future<void> _showUserDetailsDialog(User user) async {
    await showDialog(
      context: context,
      builder: (context) => UserDetailsDialog(
        user: user,
        onEditPressed: () => _showEditUserDialog(user),
      ),
    );
  }

  String _getUserRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.user:
        return 'User';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFF135BEC);
      case UserRole.user:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Users',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF135BEC).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        // More options menu
                      },
                      icon: const Icon(Icons.more_horiz, color: Color(0xFF135BEC)),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email',
                    hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            
            // Toggle Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleUserType(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _showStaff ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _showStaff ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.badge,
                                size: 20,
                                color: _showStaff ? const Color(0xFF135BEC) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Staff',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _showStaff ? FontWeight.w600 : FontWeight.w500,
                                  color: _showStaff ? const Color(0xFF135BEC) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleUserType(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_showStaff ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: !_showStaff ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ] : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: !_showStaff ? const Color(0xFF135BEC) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Customers',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: !_showStaff ? FontWeight.w600 : FontWeight.w500,
                                  color: !_showStaff ? const Color(0xFF135BEC) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Text(
                    '${_showStaff ? 'ACTIVE STAFF' : 'CUSTOMERS'} (${_filteredUsers.length})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // User List
            Expanded(
              child: _isLoading && _users.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF135BEC)))
                  : _filteredUsers.isEmpty
                      ? const Center(
                          child: Text(
                            'Không tìm thấy người dùng nào',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _filteredUsers.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredUsers.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator(color: Color(0xFF135BEC))),
                              );
                            }
                            
                            final user = _filteredUsers[index];
                            return _buildUserCard(user);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF135BEC),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF135BEC).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddUserDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.person_add, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const AdminBottomNav(currentRoute: AdminUserManagementScreen.routeName),
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getRoleColor(user.role).withOpacity(0.2),
                  width: 2,
                ),
                color: const Color(0xFFF1F5F9),
              ),
              child: user.hasProfileImage
                  ? ClipOval(
                      child: Image.network(
                        user.profileImageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildAvatarFallback(user);
                        },
                      ),
                    )
                  : _buildAvatarFallback(user),
            ),
            
            const SizedBox(width: 16),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getUserRoleDisplayName(user.role),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(user.role),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // View Button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextButton(
                onPressed: () => _showUserDetailsDialog(user),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'View',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(User user) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            _getRoleColor(user.role).withOpacity(0.1),
            _getRoleColor(user.role).withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Text(
          user.initials,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _getRoleColor(user.role),
          ),
        ),
      ),
    );
  }
}

// Add User Dialog
class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  UserRole _selectedRole = UserRole.user;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
        role: _selectedRole,
      );
      
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm Người Dùng Mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Tên đăng nhập *'),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập tên đăng nhập' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập email';
                  if (!_userService.isValidEmail(value!)) return 'Email không hợp lệ';
                  return null;
                },
              ),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Họ tên *'),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập họ tên' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu *'),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập mật khẩu';
                  if (!_userService.isValidPassword(value!)) return 'Mật khẩu phải có ít nhất 6 ký tự';
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Vai trò'),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createUser,
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Tạo'),
        ),
      ],
    );
  }
}

// Edit User Dialog
class EditUserDialog extends StatefulWidget {
  final User user;
  
  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneController;
  
  late UserRole _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with existing user data
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _passwordController = TextEditingController();
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = widget.user.copyWith(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        role: _selectedRole,
        updatedAt: DateTime.now(),
      );

      final success = await _userService.updateUser(updatedUser);
      
      if (success && mounted) {
        // If password is provided, update it separately
        if (_passwordController.text.isNotEmpty) {
          await _userService.updateUserPassword(widget.user.id!, _passwordController.text);
        }
        
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật người dùng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chỉnh sửa người dùng',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng nhập',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập tên đăng nhập';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập họ và tên';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới (để trống nếu không đổi)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Vai trò',
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role, 
                    child: Text(role.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateUser,
                    child: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Cập nhật'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// User Details Dialog
class UserDetailsDialog extends StatelessWidget {
  final User user;
  final VoidCallback? onEditPressed;
  
  const UserDetailsDialog({super.key, required this.user, this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
                border: Border.all(color: const Color(0xFF135BEC).withOpacity(0.2), width: 2),
              ),
              child: user.hasProfileImage
                  ? ClipOval(
                      child: Image.network(
                        user.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              user.initials,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF135BEC)),
                      ),
                    ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              user.displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              user.role.displayName,
              style: const TextStyle(fontSize: 14, color: Color(0xFF135BEC), fontWeight: FontWeight.w600),
            ),
            
            const SizedBox(height: 24),
            
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Tên đăng nhập', user.username),
            if (user.phoneNumber != null) _buildDetailRow('Số điện thoại', user.phoneNumber!),
            if (user.address != null) _buildDetailRow('Địa chỉ', user.address!),
            _buildDetailRow('Ngày tạo', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
            _buildDetailRow('Trạng thái', user.isActive ? 'Đang hoạt động' : 'Không hoạt động'),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onEditPressed != null) {
                      onEditPressed!();
                    }
                  },
                  child: const Text('Chỉnh sửa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF1F2937)),
            ),
          ),
        ],
      ),
    );
  }
}
