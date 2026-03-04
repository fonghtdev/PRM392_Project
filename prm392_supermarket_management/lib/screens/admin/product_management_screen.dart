import 'package:flutter/material.dart';

import '../app_bottom_nav.dart';
import '../template_asset_screen.dart';

class AdminProductManagementScreen extends StatelessWidget {
  const AdminProductManagementScreen({super.key});
  static const routeName = '/admin/products';

  @override
  Widget build(BuildContext context) {
    return const TemplateAssetScreen(
      title: 'Product Management',
      assetPath: 'lib/templates/admin/product_management.html',
      bottomNavigationBar: AdminBottomNav(currentRoute: routeName),
    );
  }
}
