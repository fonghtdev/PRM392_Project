import 'package:flutter/material.dart';

import 'checkout_payment_screen.dart';
import 'template_asset_screen.dart';

class CheckoutAddressScreen extends StatelessWidget {
  const CheckoutAddressScreen({super.key});
  static const routeName = '/checkout/address';

  @override
  Widget build(BuildContext context) {
    return TemplateAssetScreen(
      title: 'Checkout Address',
      assetPath: 'lib/templates/checkout_address.html',
      actions: [
        TextButton(
          onPressed: () => Navigator.pushNamed(
            context,
            CheckoutPaymentScreen.routeName,
          ),
          child: const Text('Next'),
        ),
      ],
    );
  }
}
