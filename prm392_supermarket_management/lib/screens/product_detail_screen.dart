import 'package:flutter/material.dart';

import 'cart_screen.dart';
import 'template_asset_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});
  static const routeName = '/product-detail';

  @override
  Widget build(BuildContext context) {
    return TemplateAssetScreen(
      title: 'Product Detail',
      assetPath: 'lib/templates/product_detail.html',
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () => Navigator.pushNamed(context, CartScreen.routeName),
        ),
      ],
    );
  }
}
