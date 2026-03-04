import 'package:flutter/material.dart';

import '../app_bottom_nav.dart';
import '../template_asset_screen.dart';

class AdminOrderManagementScreen extends StatelessWidget {
  const AdminOrderManagementScreen({super.key});
  static const routeName = '/admin/orders';

  @override
  Widget build(BuildContext context) {
    return const TemplateAssetScreen(
      title: 'Order Management',
      assetPath: 'lib/templates/admin/order_management.html',
      bottomNavigationBar: AdminBottomNav(currentRoute: routeName),
    );
  }
}
