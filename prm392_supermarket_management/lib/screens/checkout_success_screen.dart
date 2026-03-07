import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/payment.dart';
import '../repositories/order_success_repository.dart';
import 'home_screen.dart';
import 'order_history_screen.dart';

class CheckoutSuccessScreen extends StatefulWidget {
  const CheckoutSuccessScreen({
    super.key,
    this.orderId,
  });

  static const routeName = '/checkout/success';
  final int? orderId;

  @override
  State<CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends State<CheckoutSuccessScreen> {
  final OrderSuccessRepository _repository = OrderSuccessRepository();
  
  Order? _order;
  Payment? _payment;
  bool _isLoading = true;
  String _errorMessage = '';

  // Hardcoded userId for now - should come from auth service
  final int _userId = 1;

  @override
  void initState() {
    super.initState();
    // Load order data after first frame to get route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderData();
    });
  }

  Future<void> _loadOrderData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      Order? order;
      
      // Try to get orderId from route arguments first
      final args = ModalRoute.of(context)?.settings.arguments;
      int? orderIdFromArgs;
      
      if (args != null && args is int) {
        orderIdFromArgs = args;
      }
      
      // Use orderId from constructor, route arguments, or get latest order
      if (widget.orderId != null) {
        order = await _repository.getOrderById(widget.orderId!);
      } else if (orderIdFromArgs != null) {
        order = await _repository.getOrderById(orderIdFromArgs);
      } else {
        order = await _repository.getLatestOrderForUser(_userId);
      }

      if (order == null) {
        setState(() {
          _errorMessage = 'Order not found';
          _isLoading = false;
        });
        return;
      }

      // Get payment info
      final payment = await _repository.getPaymentByOrderId(order.id!);

      setState(() {
        _order = order;
        _payment = payment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load order: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      HomeScreen.routeName,
      (route) => false,
    );
  }

  void _navigateToOrderTracking() {
    // Navigate to order history/tracking screen
    Navigator.pushReplacementNamed(
      context,
      OrderHistoryScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          color: isDark ? Colors.white : Colors.black,
          onPressed: _navigateToHome,
        ),
        title: Text(
          'Order Confirmation',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 48)], // Balance the leading
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorState(isDark)
              : _buildSuccessContent(isDark),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: isDark ? Colors.red[300] : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go to Home',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessContent(bool isDark) {
    if (_order == null) return const SizedBox.shrink();

    final estimatedDelivery = _repository.calculateEstimatedDelivery(_order!.placedAt);
    final formattedDeliveryDate = _repository.formatDate(estimatedDelivery);
    
    String paymentMethodText = 'N/A';
    if (_payment != null) {
      final cardInfo = _repository.getMaskedCardNumber(_payment!.transactionRef);
      paymentMethodText = _repository.getPaymentMethodDisplay(_payment!.method, cardInfo);
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Success Icon and Message
                _buildSuccessHeader(isDark),
                
                // Order Details Card
                _buildOrderDetailsCard(
                  isDark,
                  formattedDeliveryDate,
                  paymentMethodText,
                ),
                
                // Map Preview
                _buildMapPreview(isDark),
              ],
            ),
          ),
        ),
        
        // Action Buttons
        _buildActionButtons(isDark),
      ],
    );
  }

  Widget _buildSuccessHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          // Success Icon
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF135BEC).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Color(0xFF135BEC),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Success Title
          Text(
            'Order Placed Successfully!',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Success Message
          Text(
            'Thank you for your purchase. Your order has been confirmed and is being prepared for shipment.',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(
    bool isDark,
    String deliveryDate,
    String paymentMethod,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Details',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Order ID
          _buildDetailRow(
            isDark,
            'Order ID',
            _order!.orderCode,
          ),
          
          const SizedBox(height: 16),
          
          // Estimated Delivery
          _buildDetailRow(
            isDark,
            'Estimated Delivery',
            deliveryDate,
          ),
          
          const SizedBox(height: 16),
          
          // Payment Method
          _buildDetailRow(
            isDark,
            'Payment Method',
            paymentMethod,
            icon: Icons.credit_card,
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          Divider(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          
          const SizedBox(height: 16),
          
          // Total Paid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '\$${_order!.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF135BEC),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    bool isDark,
    String label,
    String value, {
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapPreview(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(24),
      height: 128,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDxHARSrauzcRGEG7tc5ZQ529e32R3ZAw6hT5jazrc_fKU8jAZK5ptazmcLZnMKb8S4z5tm1GWiEFTbuPpTZNoCALUblYy1F5bOsGLJ2jDkfF5Nh3xWCU9o1Q0t27d4cqIKZhDX3IDqe_jV4udVzaceMybgktIZsNVTmBRXnwDLsWWqrfo866KRpKBa_MBgk3i1RUsBspX-fiUP68pzE2OHvP0uEdA_CGb_d5twrQjPulg__gqJMXzaoq4Ya2CsLWbYh_enfbSmSps',
          ),
          fit: BoxFit.cover,
          opacity: 0.6,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF135BEC),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Order processing',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Track Order Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToOrderTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.local_shipping, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Track Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Continue Shopping Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark 
                    ? const Color(0xFF334155) 
                    : const Color(0xFFE2E8F0),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue Shopping',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
