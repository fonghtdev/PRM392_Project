import 'package:flutter/material.dart';

import '../app_bottom_nav.dart';
import '../template_asset_screen.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});
  static const routeName = '/admin/users';

  @override
  Widget build(BuildContext context) {
    return const TemplateAssetScreen(
      title: 'User Management',
      assetPath: 'lib/templates/admin/user_management.html',
      bottomNavigationBar: AdminBottomNav(currentRoute: routeName),
    );
  }
}
