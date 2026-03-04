import 'package:flutter/material.dart';

import '../app_bottom_nav.dart';
import '../template_asset_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  static const routeName = '/admin/dashboard';

  @override
  Widget build(BuildContext context) {
    return const TemplateAssetScreen(
      title: 'Admin Dashboard',
      assetPath: 'lib/templates/admin/dashboard.html',
      bottomNavigationBar: AdminBottomNav(currentRoute: routeName),
    );
  }
}
