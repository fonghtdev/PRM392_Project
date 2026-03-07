import 'package:flutter/material.dart';
import '../models/address.dart';
import '../repositories/checkout_address_repository.dart';
import 'checkout_payment_screen.dart';

class CheckoutAddressScreen extends StatefulWidget {
  const CheckoutAddressScreen({super.key});

  static const routeName = '/checkout/address';

  @override
  State<CheckoutAddressScreen> createState() => _CheckoutAddressScreenState();
}

class _CheckoutAddressScreenState extends State<CheckoutAddressScreen> {
  final CheckoutAddressRepository _repository = CheckoutAddressRepository();
  bool _isLoading = true;
  List<Address> _addresses = [];
  int? _selectedAddressId;
  String _estimatedDelivery = '';

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final addresses = await _repository.getSavedAddresses();
    final delivery = await _repository.getEstimatedDelivery();

    print('🏠 Loaded ${addresses.length} addresses from database');
    if (addresses.isEmpty) {
      print('⚠️ No addresses found! Please check if database was seeded correctly.');
    }

    setState(() {
      _addresses = addresses;
      _estimatedDelivery = delivery;
      
      // Only set selected address if addresses list is not empty
      if (addresses.isNotEmpty) {
        final defaultAddress = addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => addresses.first,
        );
        _selectedAddressId = defaultAddress.id;
        print('✅ Selected address: ${defaultAddress.recipientName}');
      }
      
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Container(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(isDark),
              ),
              _buildFooter(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF21E293B) : const Color(0xF2FFFFFF),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    shape: const CircleBorder(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Shipping Address',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          _buildStepper(isDark),
        ],
      ),
    );
  }

  Widget _buildStepper(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem('1', 'Address', true, isDark),
          _buildStepConnector(isDark),
          _buildStepItem('2', 'Payment', false, isDark),
          _buildStepConnector(isDark),
          _buildStepItem('3', 'Confirm', false, isDark),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String label, bool active, bool isDark) {
    final bgColor = active
        ? const Color(0xFF135BEC)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final textColor = active
        ? const Color(0xFF135BEC)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return Opacity(
      opacity: active ? 1 : 0.4,
      child: Column(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : textColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isDark) {
    return Container(
      width: 48,
      height: 1,
      margin: const EdgeInsets.only(bottom: 22),
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildContent(bool isDark) {
    // Show empty state if no addresses
    if (_addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 80,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              'No Saved Addresses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first delivery address',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            _buildAddNewAddressButton(isDark),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Addresses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${_addresses.length} Addresses found',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._addresses.map((address) => _buildAddressCard(address, isDark)),
          const SizedBox(height: 20),
          _buildAddNewAddressButton(isDark),
          const SizedBox(height: 28),
          _buildMapCard(isDark),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address, bool isDark) {
    final isSelected = _selectedAddressId == address.id;
    final borderColor = isSelected
        ? const Color(0xFF135BEC)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    final bgColor = isSelected
        ? (isDark ? const Color(0xFF1B2A5A) : const Color(0xFFEFF4FF))
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedAddressId = address.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRadio(isSelected, isDark),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          address.recipientName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF135BEC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${address.line1}, ${address.city}, ${address.state ?? ''}, ${address.country}',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: const Color(0x33135BEC),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.edit, size: 16, color: Color(0xFF135BEC)),
                            label: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: Color(0xFF135BEC),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {},
                            icon: Icon(
                              Icons.delete,
                              size: 16,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            label: Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(bool isSelected, bool isDark) {
    return Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: 2,
          color: isSelected
              ? const Color(0xFF135BEC)
              : (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5F5)),
        ),
        color: isSelected ? const Color(0xFF135BEC) : Colors.transparent,
      ),
      child: isSelected
          ? const Center(
              child: CircleAvatar(radius: 4, backgroundColor: Colors.white),
            )
          : null,
    );
  }

  Widget _buildAddNewAddressButton(bool isDark) {
    return OutlinedButton.icon(
      onPressed: () => _showAddAddressDialog(),
      icon: const Icon(Icons.add_location_alt),
      label: const Text('Add New Address'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        side: BorderSide(
          color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
          width: 1,
          style: BorderStyle.solid,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildMapCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBzHuQQhPYjiCUk0lmDwa-R85ZSNPQpE4ADJUkM3fhznXrDx58_SD5n0bZcF0QIqB64D-Tr7bX94XO9iaghBotj6QI2FgZ_Xhopjbr4i_55RIIev-P8vRWfCEZb5lauQkQ-vaikmCHzoCwa8XQRYmM63g_NvVONJ2MmuumXgeLcekSdWysz-vywaobt5O7f1ZnLUfHA-bIjKg7CtqXxQiyGCV1LSa0kWkgeoeBnOx2e2R6N6Mn2kUF7X-Yy9EPNoRi2cmKBochP8eo',
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC0F172A)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135BEC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.map, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text(
                  'View nearby collection points',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    final selected = _addresses.firstWhere(
      (addr) => addr.id == _selectedAddressId,
      orElse: () => _addresses.isNotEmpty ? _addresses.first : Address(
        id: 0,
        userId: 0,
        recipientName: '',
        phone: '',
        line1: '',
        city: '',
        country: '',
        createdAt: DateTime.now(),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deliver to ${selected.recipientName}'.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selected.line1.isNotEmpty ? '${selected.line1}...' : '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Estimated Delivery',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _estimatedDelivery,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF135BEC),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addresses.isEmpty || _selectedAddressId == null
                  ? null
                  : () => Navigator.pushNamed(
                        context,
                        CheckoutPaymentScreen.routeName,
                      ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Continue to Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: const Color(0x40135BEC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddAddressDialog() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final formKey = GlobalKey<FormState>();
    final recipientNameController = TextEditingController();
    final phoneController = TextEditingController();
    final line1Controller = TextEditingController();
    final line2Controller = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final postalCodeController = TextEditingController();
    bool isDefault = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            'Add New Address',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: recipientNameController,
                    decoration: InputDecoration(
                      labelText: 'Recipient Name *',
                      labelStyle: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter recipient name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      labelStyle: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter phone number' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: line1Controller,
                    decoration: InputDecoration(
                      labelText: 'Address Line 1 *',
                      labelStyle: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter address' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: line2Controller,
                    decoration: InputDecoration(
                      labelText: 'Address Line 2 (Optional)',
                      labelStyle: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: cityController,
                          decoration: InputDecoration(
                            labelText: 'City *',
                            labelStyle: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: stateController,
                          decoration: InputDecoration(
                            labelText: 'State/District',
                            labelStyle: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: postalCodeController,
                    decoration: InputDecoration(
                      labelText: 'Postal Code',
                      labelStyle: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text(
                      'Set as default address',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    value: isDefault,
                    onChanged: (value) => setState(() => isDefault = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Address'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      // Create new address
      final newAddress = Address(
        id: null,
        userId: 1, // TODO: Get from auth service
        recipientName: recipientNameController.text.trim(),
        phone: phoneController.text.trim(),
        line1: line1Controller.text.trim(),
        line2: line2Controller.text.trim().isEmpty ? null : line2Controller.text.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim().isEmpty ? null : stateController.text.trim(),
        postalCode: postalCodeController.text.trim().isEmpty
            ? null
            : postalCodeController.text.trim(),
        country: 'VN',
        isDefault: isDefault,
        createdAt: DateTime.now(),
      );

      try {
        await _repository.addNewAddress(newAddress);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Reload addresses
          _loadAddresses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add address: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    // Dispose controllers
    recipientNameController.dispose();
    phoneController.dispose();
    line1Controller.dispose();
    line2Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
  }
}
