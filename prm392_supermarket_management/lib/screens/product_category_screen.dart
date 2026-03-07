import 'package:flutter/material.dart';

import 'app_bottom_nav.dart';
import 'product_catalog_screen.dart';

class ProductCategoryScreen extends StatelessWidget {
  const ProductCategoryScreen({super.key});
  static const routeName = '/categories';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ProductCatalogScreen(),
      bottomNavigationBar: const CustomerBottomNav(currentRoute: routeName),
    );
  }
}
