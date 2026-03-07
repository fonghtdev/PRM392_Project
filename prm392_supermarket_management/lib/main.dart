import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/app_database.dart';
import 'services/seed_data_service.dart';
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
import 'screens/user/product_detail_screen.dart' as user_product_detail;
import 'screens/user_profile_screen.dart';
import 'screens/database_test_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 🔥 UNCOMMENT DÒNG DƯỚI ĐỂ RESET DATABASE (chạy 1 lần rồi comment lại)
  // await _resetDatabase();

  await AppDatabase.instance.database;

  // Thêm dữ liệu mẫu cho dashboard (chỉ trong development)
  if (kDebugMode) {
    try {
      await SeedDataService.addSampleOrders();
      print('🎯 Dashboard orders data ready!');
    } catch (e) {
      print('Lỗi khi setup sample data: $e');
    }
  }

  runApp(const MainApp());
}

/// Reset database để trigger upgrade và seed data mới
Future<void> _resetDatabase() async {
  try {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/supermarket_management.db';
    await deleteDatabase(path);
    print('✅ Database đã được reset - sẽ seed lại data addresses');
  } catch (e) {
    print('❌ Lỗi khi reset database: $e');
  }
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
        user_product_detail.ProductDetailScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final productId = args is int ? args : 1;
          return user_product_detail.ProductDetailScreen(productId: productId);
        },
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
        DatabaseTestScreen.routeName: (context) => const DatabaseTestScreen(),
      },
    );
  }
}
