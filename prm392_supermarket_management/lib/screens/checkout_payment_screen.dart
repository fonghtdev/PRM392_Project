import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/payment_method.dart';
import '../models/saved_card.dart';
import '../repositories/checkout_payment_repository.dart';
import '../services/cart_service.dart';
import '../services/checkout_service.dart';
import 'checkout_success_screen.dart';

class CheckoutPaymentScreen extends StatefulWidget {
  const CheckoutPaymentScreen({super.key});
  static const routeName = '/checkout/payment';

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  final CheckoutPaymentRepository _repository = CheckoutPaymentRepository();
  final CartService _cartService = CartService();
  final CheckoutService _checkoutService = CheckoutService();
  final TextEditingController _promoCodeController = TextEditingController();

  bool _isLoading = true;
  bool _isProcessing = false;
  List<PaymentMethod> _paymentMethods = [];
  List<SavedCard> _savedCards = [];
  List<CartItem> _cartItems = [];
  PaymentMethod? _selectedPaymentMethod;
  SavedCard? _selectedCard;
  
  double _subtotal = 0.0;
  double _shipping = 0.0;
  double _discount = 0.0;
  bool _isPromoApplied = false;
  String? _promoErrorMessage;
  int _userId = 1; // TODO: Get from auth service

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentData() async {
    setState(() => _isLoading = true);

    try {
      // Load cart items to calculate subtotal
      final cartItems = await _cartService.getCartItems(_userId);
      final calculatedSubtotal = cartItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );
      
      // Calculate shipping fee based on subtotal
      final calculatedShipping = _cartService.calculateShippingFee(calculatedSubtotal);

      // Load payment methods and saved cards
      final methods = await _repository.getPaymentMethods();
      final cards = await _repository.getSavedCards(userId: _userId);

      setState(() {
        _cartItems = cartItems; // Store cart items for order creation
        _subtotal = calculatedSubtotal;
        _shipping = calculatedShipping;
        _paymentMethods = methods;
        _savedCards = cards;
        _selectedPaymentMethod = methods.isNotEmpty ? methods.first : null;
        _selectedCard = cards.isNotEmpty && cards.any((c) => c.isDefault) 
            ? cards.firstWhere((c) => c.isDefault) 
            : (cards.isNotEmpty ? cards.first : null);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payment data: $e')),
        );
      }
    }
  }

  Future<void> _applyPromoCode() async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _promoErrorMessage = 'Please enter a promo code';
      });
      return;
    }

    try {
      final result = await _repository.applyPromoCode(code);
      
      if (result['success']) {
        setState(() {
          _discount = result['discount'];
          _isPromoApplied = true;
          _promoErrorMessage = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Promo code applied! You saved \$${_discount.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _promoErrorMessage = result['message'];
          _isPromoApplied = false;
        });
      }
    } catch (e) {
      setState(() {
        _promoErrorMessage = 'Error applying promo code';
      });
    }
  }

  Future<void> _confirmPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (_selectedPaymentMethod!.id == 'card' && _selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a card')),
      );
      return;
    }

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    // Show loading
    setState(() => _isProcessing = true);

    try {
      // Get transaction reference (card number for card payments)
      String? transactionRef;
      if (_selectedPaymentMethod!.id == 'card' && _selectedCard != null) {
        transactionRef = _selectedCard!.cardNumber;
      }

      // Create order in database
      final orderId = await _checkoutService.createOrderFromCart(
        userId: _userId,
        addressId: null, // TODO: Get from address selection
        cartItems: _cartItems,
        subtotal: _subtotal,
        shippingFee: _shipping,
        discount: _discount,
        paymentMethod: _selectedPaymentMethod!.id,
        transactionRef: transactionRef,
      );

      // Navigate to success screen with the new order ID
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          CheckoutSuccessScreen.routeName,
          arguments: orderId,
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double get _total => _subtotal + _shipping - _discount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Method',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(isDark),
                
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPaymentMethods(isDark),
                        const SizedBox(height: 24),
                        _buildPromoCodeSection(isDark),
                        const SizedBox(height: 24),
                        if (_selectedPaymentMethod?.id == 'card')
                          _buildSavedCards(isDark),
                      ],
                    ),
                  ),
                ),

                // Footer with total and confirm button
                _buildFooter(isDark),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              _buildStepIndicator(1, 'Address', true, isDark),
              Expanded(child: _buildStepLine(true, isDark)),
              _buildStepIndicator(2, 'Payment', true, isDark),
              Expanded(child: _buildStepLine(false, isDark)),
              _buildStepIndicator(3, 'Review', false, isDark),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.66, // 2 out of 3 steps
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF135BEC)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isComplete, bool isDark) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete ? const Color(0xFF135BEC) : (isDark ? Colors.grey[800] : Colors.grey[300]),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isComplete ? const Color(0xFF135BEC) : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isComplete, bool isDark) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: isComplete ? const Color(0xFF135BEC) : (isDark ? Colors.grey[800] : Colors.grey[300]),
    );
  }

  Widget _buildPaymentMethods(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ..._paymentMethods.map((method) => _buildPaymentMethodTile(method, isDark)),
      ],
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method, bool isDark) {
    final isSelected = _selectedPaymentMethod?.id == method.id;
    
    Color getMethodColor() {
      switch (method.colorClass) {
        case 'primary':
          return const Color(0xFF135BEC);
        case 'success':
          return Colors.green;
        case 'warning':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    IconData getMethodIcon() {
      switch (method.icon) {
        case 'credit_card':
          return Icons.credit_card;
        case 'account_balance':
          return Icons.account_balance;
        case 'local_shipping':
          return Icons.local_shipping;
        default:
          return Icons.payment;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF135BEC) : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: getMethodColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                getMethodIcon(),
                color: getMethodColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: method.id,
              groupValue: _selectedPaymentMethod?.id,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = method;
                });
              },
              activeColor: const Color(0xFF135BEC),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promo Code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoCodeController,
                      enabled: !_isPromoApplied,
                      decoration: InputDecoration(
                        hintText: 'Enter promo code',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF135BEC),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isPromoApplied ? null : _applyPromoCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPromoApplied ? Colors.green : const Color(0xFF135BEC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_isPromoApplied ? 'Applied' : 'Apply'),
                  ),
                ],
              ),
              if (_promoErrorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _promoErrorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
              if (_isPromoApplied) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Promo code applied! You saved \$${_discount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavedCards(bool isDark) {
    if (_savedCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.credit_card_off,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No saved cards',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a card to make payment easier',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Cards',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _savedCards.length,
            itemBuilder: (context, index) {
              final card = _savedCards[index];
              return _buildCardItem(card, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(SavedCard card, bool isDark) {
    final isSelected = _selectedCard?.id == card.id;
    
    Color getCardColor() {
      switch (card.cardType.toLowerCase()) {
        case 'visa':
          return const Color(0xFF1A1F71);
        case 'mastercard':
          return const Color(0xFFEB001B);
        case 'amex':
          return const Color(0xFF006FCF);
        default:
          return const Color(0xFF135BEC);
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCard = card;
        });
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              getCardColor(),
              getCardColor().withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.cardType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (card.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    card.maskedNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARD HOLDER',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.cardHolder,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXPIRES',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.expiryDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF135BEC),
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  '\$${_subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shipping',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  _shipping == 0 ? 'Free' : '\$${_shipping.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _shipping == 0 ? Colors.green : (isDark ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
            if (_discount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    '-\$${_discount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF135BEC),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Confirm & Pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
