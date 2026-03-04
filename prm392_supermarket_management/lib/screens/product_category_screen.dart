import 'package:flutter/material.dart';

import 'app_bottom_nav.dart';
import 'template_asset_screen.dart';

class ProductCategoryScreen extends StatelessWidget {
  const ProductCategoryScreen({super.key});
  static const routeName = '/categories';

  @override
  Widget build(BuildContext context) {
    return const TemplateAssetScreen(
      title: 'Categories',
      assetPath: 'lib/templates/product_category.html',
      showAppBar: false,
      bottomNavigationBar: CustomerBottomNav(currentRoute: routeName),
    );
  }
}
