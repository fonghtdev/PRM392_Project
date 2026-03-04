import 'package:flutter/material.dart';

import 'checkout_success_screen.dart';
import 'template_asset_screen.dart';

class CheckoutPaymentScreen extends StatelessWidget {
  const CheckoutPaymentScreen({super.key});
  static const routeName = '/checkout/payment';

  @override
  Widget build(BuildContext context) {
    return TemplateAssetScreen(
      title: 'Checkout Payment',
      assetPath: 'lib/templates/checkout_payment.html',
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pushNamed(context, CheckoutSuccessScreen.routeName),
          child: const Text('Pay'),
        ),
      ],
    );
  }
}
