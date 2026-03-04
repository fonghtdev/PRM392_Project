import 'package:flutter/material.dart';

import 'app_bottom_nav.dart';
import 'template_asset_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    return const TemplateAssetScreen(
      title: 'Home',
      assetPath: 'lib/templates/home_screen.html',
      bottomNavigationBar: CustomerBottomNav(currentRoute: routeName),
    );
  }
}
