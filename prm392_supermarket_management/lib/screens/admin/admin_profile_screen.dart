import 'package:flutter/material.dart';

import '../app_bottom_nav.dart';
import '../login_screen.dart';
import '../template_asset_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});
  static const routeName = '/admin/profile';

  @override
  Widget build(BuildContext context) {
    return TemplateAssetScreen(
      title: 'Admin Profile',
      assetPath: 'lib/templates/admin/admin_profile.html',
      javascriptChannels: {
        'AdminProfileChannel': (message) {
          if (message.trim().toLowerCase() == 'logout') {
            Navigator.pushNamedAndRemoveUntil(
              context,
              LoginScreen.routeName,
              (route) => false,
            );
          }
        },
      },
      bottomNavigationBar: const AdminBottomNav(currentRoute: routeName),
    );
  }
}
