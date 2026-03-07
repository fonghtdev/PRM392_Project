import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../services/user_service.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});
  static const routeName = '/debug/database-test';

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  final UserService _userService = UserService();
  String _debugOutput = 'Tap button to test database';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testDatabase,
              child: const Text('Test Database'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _debugOutput,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testDatabase() async {
    setState(() {
      _debugOutput = 'Testing database...\n';
    });

    try {
      // Test 1: Check database connection
      _addOutput('📱 Testing database connection...');
      final db = await AppDatabase.instance.database;
      _addOutput('✅ Database connected successfully');

      // Test 2: Check users table schema
      _addOutput('\n🔍 Checking users table schema...');
      final tables = await db.rawQuery("SELECT sql FROM sqlite_master WHERE type='table' AND name='users'");
      if (tables.isNotEmpty) {
        _addOutput('✅ Users table exists');
        _addOutput('Schema: ${tables.first['sql']}');
      } else {
        _addOutput('❌ Users table not found');
        return;
      }

      // Test 3: Check all users in database
      _addOutput('\n👥 Checking all users in database...');
      final allUsers = await db.query('users');
      _addOutput('Found ${allUsers.length} users:');
      for (final user in allUsers) {
        _addOutput('- ID: ${user['id']}, Username: ${user['username']}, Role: ${user['role']}, Active: ${user['is_active']}');
      }

      // Test 4: Test UserService
      _addOutput('\n🔧 Testing UserService...');
      final admin = await _userService.getCurrentAdmin();
      if (admin != null) {
        _addOutput('✅ Admin found: ${admin.fullName} (${admin.email})');
        _addOutput('Phone: ${admin.phoneNumber ?? 'null'}');
        _addOutput('Address: ${admin.address ?? 'null'}');
        _addOutput('Profile Image: ${admin.profileImageUrl ?? 'null'}');
      } else {
        _addOutput('❌ No admin found');
      }

      // Test 5: Test specific query
      _addOutput('\n🔎 Testing admin query directly...');
      final adminUsers = await db.query(
        'users',
        where: 'role = ? AND is_active = ?',
        whereArgs: ['admin', 1],
      );
      _addOutput('Direct admin query found ${adminUsers.length} results');
      for (final adminUser in adminUsers) {
        _addOutput('- Admin: ${adminUser['full_name']} (${adminUser['username']})');
      }

    } catch (e) {
      _addOutput('❌ Error: $e');
    }
  }

  void _addOutput(String message) {
    setState(() {
      _debugOutput += '$message\n';
    });
  }
}