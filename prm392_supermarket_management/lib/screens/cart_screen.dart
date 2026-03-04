import 'package:flutter/material.dart';

import 'app_bottom_nav.dart';
import 'checkout_address_screen.dart';
import 'template_asset_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  static const routeName = '/cart';

  @override
  Widget build(BuildContext context) {
    return TemplateAssetScreen(
      title: 'Cart',
      assetPath: 'lib/templates/cart.html',
      actions: [
        TextButton(
          onPressed: () => Navigator.pushNamed(
            context,
            CheckoutAddressScreen.routeName,
          ),
          child: const Text('Checkout'),
        ),
      ],
      bottomNavigationBar: const CustomerBottomNav(currentRoute: routeName),
    );
  }
}
