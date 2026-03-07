import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/transaction.dart';
import '../../services/user_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/contact_item.dart';
import '../../widgets/action_button.dart';
import '../app_bottom_nav.dart';
import '../login_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});
  static const routeName = '/admin/profile';

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final UserService _userService = UserService();
  final TransactionService _transactionService = TransactionService();
  late Future<User?> _adminFuture;
  late Future<List<Transaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _adminFuture = _loadAdmin();
    _transactionsFuture = _loadTransactions();
  }

  Future<User?> _loadAdmin() async {
    try {
      print('🔍 Loading admin user...');
      final admin = await _userService.getCurrentAdmin();
      print('✅ Admin loaded: ${admin?.fullName ?? 'null'}');
      return admin;
    } catch (e) {
      print('❌ Error loading admin: $e');
      rethrow;
    }
  }

  Future<List<Transaction>> _loadTransactions() async {
    try {
      print('🔍 Loading recent transactions...');
      final transactions = await _transactionService.getRecentTransactions(limit: 5);
      print('✅ Transactions loaded: ${transactions.length} items');
      return transactions;
    } catch (e) {
      print('❌ Error loading transactions: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF135BEC), // Primary blue
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F6F8),
      ),
      child: Scaffold(
        body: Column(
          children: [
            // Header
            _buildHeader(context),
            // Body
            Expanded(
              child: FutureBuilder<User?>(
                future: _adminFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final admin = snapshot.data;
                  if (admin == null) {
                    return const Center(
                      child: Text('No admin user found'),
                    );
                  }

                  return _buildBody(context, admin);
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: const AdminBottomNav(currentRoute: AdminProfileScreen.routeName),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 24),
            ),
          ),
          const Expanded(
            child: Text(
              'User Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // More options - could add settings, logout, etc.
              },
              icon: const Icon(Icons.more_horiz, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, User admin) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Section
          _buildProfileSection(context, admin),
          const SizedBox(height: 16),
          // Contact Details
          _buildContactDetails(context, admin),
          const SizedBox(height: 24),
          // Staff Permissions
          _buildStaffPermissions(context, admin),
          const SizedBox(height: 24),
          // Transaction History
          _buildTransactionHistory(context),
          const SizedBox(height: 32),
          // Logout Button
          _buildLogoutSection(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, User admin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Avatar and info
          Column(
            children: [
              ProfileAvatar(
                imageUrl: admin.profileImageUrl,
                initials: admin.initials,
                size: 128,
                showBorder: true,
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  Text(
                    admin.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    admin.jobTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      admin.statusBadge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Action Buttons
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Row(
              children: [
                ActionButton(
                  icon: Icons.edit,
                  label: 'Edit Profile',
                  onPressed: () {
                    // Navigate to EditAdminScreen
                    _navigateToEditProfile(admin);
                  },
                ),
                const SizedBox(width: 12),
                ActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  onPressed: () => _showDeleteConfirmation(context, admin),
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDetails(BuildContext context, User admin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'CONTACT DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ContactItem(
                  icon: Icons.mail,
                  label: 'Email Address',
                  value: admin.email,
                  onTap: () {
                    // Handle email tap
                  },
                ),
                ContactItem(
                  icon: Icons.phone,
                  label: 'Phone Number',
                  value: admin.phoneNumber ?? 'Not provided',
                  onTap: () {
                    // Handle phone tap
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffPermissions(BuildContext context, User admin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'STAFF PERMISSIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...admin.permissions.map((permission) => _buildPermissionChip(
                  context, 
                  permission, 
                  isActive: permission != 'Financial Reports',
                )),
                _buildPermissionChip(
                  context,
                  '+ Add Access',
                  isAddButton: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionChip(
    BuildContext context, 
    String label, {
    bool isActive = true,
    bool isAddButton = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAddButton 
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAddButton 
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isAddButton ? FontWeight.bold : FontWeight.w500,
          color: isAddButton
              ? Theme.of(context).primaryColor
              : (isActive ? Colors.black87 : Colors.grey.shade400),
          decoration: !isActive && !isAddButton 
              ? TextDecoration.lineThrough 
              : null,
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TRANSACTION HISTORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.0,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // View all transactions
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: FutureBuilder<List<Transaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Error loading transactions: ${snapshot.error}'),
                  );
                }

                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No transactions found'),
                  );
                }

                return Column(
                  children: transactions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final transaction = entry.value;
                    return _buildTransactionItem(
                      icon: _getTransactionIcon(transaction.type),
                      title: transaction.description,
                      subtitle: '${transaction.statusDisplayName} • ${_formatTransactionDate(transaction.createdAt)}',
                      amount: '${transaction.isNegative ? "-" : "+"}\$${transaction.amount.toStringAsFixed(2)}',
                      amountColor: transaction.isNegative ? Colors.red.shade600 : Colors.green.shade600,
                      isLast: index == transactions.length - 1,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.purchase:
        return Icons.shopping_bag;
      case TransactionType.refund:
        return Icons.replay;
      case TransactionType.adjustment:
        return Icons.tune;
    }
  }

  String _formatTransactionDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    Color? amountColor,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: !isLast 
            ? Border(bottom: BorderSide(color: Colors.grey.shade100))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: amountColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _handleLogout(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.red.shade500,
            elevation: 0,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade100),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEditProfile(User admin) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: admin.fullName),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: admin.email),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: admin.phoneNumber),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  controller: TextEditingController(text: admin.address),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, User admin) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Admin Account'),
          content: Text(
            'Are you sure you want to delete the admin account for ${admin.fullName}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAdmin(admin);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAdmin(User admin) async {
    try {
      final success = await _userService.deleteCurrentAdmin(admin.id!);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin account deleted successfully')),
          );
          // Navigate back to login
          Navigator.pushNamedAndRemoveUntil(
            context,
            LoginScreen.routeName,
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete admin account')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _handleLogout(BuildContext context) async {
    try {
      await _userService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          LoginScreen.routeName,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout error: ${e.toString()}')),
        );
      }
    }
  }
}
