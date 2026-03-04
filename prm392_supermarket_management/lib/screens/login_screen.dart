import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/app_database.dart';
import 'admin/dashboard_screen.dart';
import 'home_screen.dart';
import 'template_asset_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, this.onLoginSuccess});

  static const routeName = '/login';
  final VoidCallback? onLoginSuccess;

  Future<void> _handleLoginMessage(BuildContext context, String message) async {
    try {
      final payload = jsonDecode(message);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Invalid payload');
      }

      final username = (payload['username']?.toString() ?? '').trim();
      final password = (payload['password']?.toString() ?? '').trim();
      if (username.isEmpty || password.isEmpty) {
        throw const FormatException('Missing credentials');
      }

      final user = await AppDatabase.instance.authenticateUser(
        username: username,
        password: password,
      );

      if (!context.mounted) {
        return;
      }

      if (user == null) {
        _showInvalidLogin(context);
        return;
      }

      final role = (user['role']?.toString() ?? '').toLowerCase();
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, AdminDashboardScreen.routeName);
        onLoginSuccess?.call();
        return;
      }

      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      onLoginSuccess?.call();
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showInvalidLogin(context);
    }
  }

  void _showInvalidLogin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sai tai khoan/mat khau. Dung admin/1 hoac user/2'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TemplateAssetScreen(
      title: 'Login',
      assetPath: 'lib/templates/login.html',
      javascriptChannels: {
        'LoginChannel': (message) => _handleLoginMessage(context, message),
      },
    );
  }
}
