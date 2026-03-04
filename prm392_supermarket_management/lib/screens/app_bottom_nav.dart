import 'package:flutter/material.dart';

import 'admin/admin_profile_screen.dart';
import 'admin/dashboard_screen.dart';
import 'admin/order_management_screen.dart';
import 'admin/product_management_screen.dart';
import 'admin/user_management_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'order_history_screen.dart';
import 'product_category_screen.dart';
import 'user_profile_screen.dart';

class CustomerBottomNav extends StatelessWidget {
  const CustomerBottomNav({super.key, required this.currentRoute});

  final String currentRoute;

  static const _routes = <String>[
    HomeScreen.routeName,
    ProductCategoryScreen.routeName,
    CartScreen.routeName,
    OrderHistoryScreen.routeName,
    UserProfileScreen.routeName,
  ];

  int get _currentIndex {
    final index = _routes.indexOf(currentRoute);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) {
        final targetRoute = _routes[index];
        if (targetRoute != currentRoute) {
          Navigator.pushReplacementNamed(context, targetRoute);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Categories'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({super.key, required this.currentRoute});

  final String currentRoute;

  static const _routes = <String>[
    AdminDashboardScreen.routeName,
    AdminProductManagementScreen.routeName,
    AdminOrderManagementScreen.routeName,
    AdminUserManagementScreen.routeName,
    AdminProfileScreen.routeName,
  ];

  int get _currentIndex {
    final index = _routes.indexOf(currentRoute);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) {
        final targetRoute = _routes[index];
        if (targetRoute != currentRoute) {
          Navigator.pushReplacementNamed(context, targetRoute);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Users'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Profile'),
      ],
    );
  }
}
