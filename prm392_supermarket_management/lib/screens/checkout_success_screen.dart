import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'template_asset_screen.dart';

class CheckoutSuccessScreen extends StatelessWidget {
  const CheckoutSuccessScreen({super.key});
  static const routeName = '/checkout/success';

  @override
  Widget build(BuildContext context) {
    return TemplateAssetScreen(
      title: 'Checkout Success',
      assetPath: 'lib/templates/checkout_success_confirm.html',
      actions: [
        TextButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            HomeScreen.routeName,
            (route) => false,
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
