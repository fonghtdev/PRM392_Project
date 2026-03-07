import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/suggested_product.dart';
import '../repositories/cart_repository.dart';
import 'app_bottom_nav.dart';
import 'checkout_address_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  static const routeName = '/cart';

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartRepository _repository = CartRepository();
  List<CartItem> _cartItems = [];
  List<SuggestedProduct> _suggestedProducts = [];
  bool _isLoading = true;
  
  // TODO: Get from logged in user session
  // For now, using default user ID
  final int _currentUserId = 1;

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    setState(() => _isLoading = true);
    final cartItems = await _repository.getCartItems(_currentUserId);
    final suggested = await _repository.getSuggestedProducts(_currentUserId);
    setState(() {
      _cartItems = cartItems;
      _suggestedProducts = suggested;
      _isLoading = false;
    });
  }

  void _updateQuantity(int productId, int delta) async {
    final index = _cartItems.indexWhere((item) => item.id == productId);
    if (index == -1) return;

    final newQuantity = _cartItems[index].quantity + delta;
    if (newQuantity < 1) return;

    setState(() {
      _cartItems[index].quantity = newQuantity;
    });

    await _repository.updateQuantity(_currentUserId, productId, newQuantity);
  }

  void _removeItem(int productId) async {
    await _repository.removeItem(_currentUserId, productId);
    setState(() {
      _cartItems.removeWhere((item) => item.id == productId);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item removed from cart'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _proceedToCheckout() {
    Navigator.pushNamed(context, CheckoutAddressScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(isDark),
                ),
              ],
            ),
            _buildCheckoutBottom(isDark),
          ],
        ),
      ),
      bottomNavigationBar: const CustomerBottomNav(currentRoute: CartScreen.routeName),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.arrow_back_ios,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Shopping Cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              // More options
            },
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.more_horiz,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 280),
      children: [
        _buildFreeShippingProgress(isDark),
        ..._cartItems.map((item) => _buildCartItem(item, isDark)),
        _buildSuggestedProducts(isDark),
      ],
    );
  }

  Widget _buildFreeShippingProgress(bool isDark) {
    final remaining = _repository.calculateRemainingForFreeShipping(_cartItems);
    final progress = _repository.calculateFreeShippingProgress(_cartItems);
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    children: [
                      const TextSpan(text: 'Add '),
                      TextSpan(
                        text: '\$${remaining.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF135BEC),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ' for free shipping'),
                    ],
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              height: 8,
              width: double.infinity,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  color: const Color(0xFF135BEC),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                child: const Icon(Icons.image, size: 40),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeItem(item.id),
                      child: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.variant,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF135BEC),
                      ),
                    ),
                    _buildQuantityControl(item, isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(CartItem item, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _updateQuantity(item.id, -1),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '−',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '${item.quantity}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _updateQuantity(item.id, 1),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF135BEC),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedProducts(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You might also like',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestedProducts
                  .map((product) => _buildSuggestedProductCard(product, isDark))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedProductCard(SuggestedProduct product, bool isDark) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  child: const Icon(Icons.image, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF135BEC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBottom(bool isDark) {
    final subtotal = _repository.calculateSubtotal(_cartItems);
    final shippingFee = _repository.calculateShippingFee(subtotal);
    final total = _repository.calculateTotal(_cartItems);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 80,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriceRow(
              'Subtotal',
              '\$${subtotal.toStringAsFixed(2)}',
              isDark,
              isSubtitle: true,
            ),
            const SizedBox(height: 8),
            _buildPriceRow(
              'Shipping Fee',
              '\$${shippingFee.toStringAsFixed(2)}',
              isDark,
              isGreen: true,
              isSubtitle: true,
            ),
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriceRow(
                  'Estimated Total',
                  '\$${total.toStringAsFixed(2)}',
                  isDark,
                  isBold: true,
                ),
                const SizedBox(height: 4),
                Text(
                  'Promo codes can be applied at checkout',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceedToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    bool isGreen = false,
    bool isSubtitle = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isSubtitle
                ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 20 : 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: isGreen
                ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                : (isBold
                    ? const Color(0xFF135BEC)
                    : (isDark ? Colors.white : const Color(0xFF0F172A))),
          ),
        ),
      ],
    );
  }
}
