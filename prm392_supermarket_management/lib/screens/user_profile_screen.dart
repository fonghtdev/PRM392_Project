import 'package:flutter/material.dart';

import 'app_bottom_nav.dart';
import 'login_screen.dart';
import 'template_asset_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});
  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    return TemplateAssetScreen(
      title: 'Profile',
      assetPath: 'lib/templates/user_profile.html',
      javascriptChannels: {
        'ProfileChannel': (message) {
          if (message.trim().toLowerCase() == 'logout') {
            Navigator.pushNamedAndRemoveUntil(
              context,
              LoginScreen.routeName,
              (route) => false,
            );
          }
        },
      },
      bottomNavigationBar: const CustomerBottomNav(currentRoute: routeName),
    );
  }
}
