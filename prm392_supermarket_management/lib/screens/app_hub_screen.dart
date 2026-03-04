import 'package:flutter/material.dart';

class AppHubScreen extends StatelessWidget {
  const AppHubScreen({super.key});

  static const routeName = '/hub';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supermarket Screens')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Customer', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _RouteButton(label: 'Home', route: '/home'),
          _RouteButton(label: 'Categories', route: '/categories'),
          _RouteButton(label: 'Product Detail', route: '/product-detail'),
          _RouteButton(label: 'Cart', route: '/cart'),
          _RouteButton(label: 'Checkout Address', route: '/checkout/address'),
          _RouteButton(label: 'Checkout Payment', route: '/checkout/payment'),
          _RouteButton(label: 'Checkout Success', route: '/checkout/success'),
          _RouteButton(label: 'Order History', route: '/orders'),
          _RouteButton(label: 'Profile', route: '/profile'),
          const SizedBox(height: 16),
          Text('Admin', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _RouteButton(label: 'Dashboard', route: '/admin/dashboard'),
          _RouteButton(label: 'Product Management', route: '/admin/products'),
          _RouteButton(label: 'Order Management', route: '/admin/orders'),
          _RouteButton(label: 'User Management', route: '/admin/users'),
          _RouteButton(label: 'Admin Profile', route: '/admin/profile'),
        ],
      ),
    );
  }
}

class _RouteButton extends StatelessWidget {
  const _RouteButton({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, route),
        child: Text(label),
      ),
    );
  }
}
