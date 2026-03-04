import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/app_database.dart';
import 'screens/admin/admin_profile_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/order_management_screen.dart';
import 'screens/admin/product_management_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/app_hub_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_address_screen.dart';
import 'screens/checkout_payment_screen.dart';
import 'screens/checkout_success_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/product_category_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/user_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await AppDatabase.instance.database;

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supermarket Management',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF135BEC)),
      ),
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        AppHubScreen.routeName: (context) => const AppHubScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        ProductCategoryScreen.routeName: (context) =>
            const ProductCategoryScreen(),
        ProductDetailScreen.routeName: (context) => const ProductDetailScreen(),
        CartScreen.routeName: (context) => const CartScreen(),
        CheckoutAddressScreen.routeName: (context) =>
            const CheckoutAddressScreen(),
        CheckoutPaymentScreen.routeName: (context) =>
            const CheckoutPaymentScreen(),
        CheckoutSuccessScreen.routeName: (context) =>
            const CheckoutSuccessScreen(),
        OrderHistoryScreen.routeName: (context) => const OrderHistoryScreen(),
        UserProfileScreen.routeName: (context) => const UserProfileScreen(),
        AdminDashboardScreen.routeName: (context) =>
            const AdminDashboardScreen(),
        AdminProductManagementScreen.routeName: (context) =>
            const AdminProductManagementScreen(),
        AdminOrderManagementScreen.routeName: (context) =>
            const AdminOrderManagementScreen(),
        AdminUserManagementScreen.routeName: (context) =>
            const AdminUserManagementScreen(),
        AdminProfileScreen.routeName: (context) => const AdminProfileScreen(),
      },
    );
  }
}
