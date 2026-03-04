import 'package:flutter/material.dart';

import 'app_bottom_nav.dart';
import 'template_asset_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});
  static const routeName = '/orders';

  @override
  Widget build(BuildContext context) {
    return const TemplateAssetScreen(
      title: 'Order History',
      assetPath: 'lib/templates/order_history.html',
      bottomNavigationBar: CustomerBottomNav(currentRoute: routeName),
    );
  }
}
