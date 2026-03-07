import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../app_bottom_nav.dart';
import 'widgets/order_details_dialog.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});
  static const routeName = '/admin/orders';

  @override
  State<AdminOrderManagementScreen> createState() => _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen> {
  final OrderService _orderService = OrderService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Order> _orders = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  OrderStatus? _selectedStatus;
  String _searchQuery = '';
  Map<String, int> _orderStats = {
    'todayOrders': 0,
    'totalRevenue': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadOrderStats();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _orders.clear();
      _hasMore = true;
    });

    try {
      final orders = await _orderService.getOrders(
        page: _currentPage,
        limit: 20,
        status: _selectedStatus,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _orders = orders;
        _hasMore = orders.length == 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadOrderStats() async {
    try {
      final stats = await _orderService.getOrderStats();
      setState(() {
        _orderStats = {
          'todayOrders': stats.todayOrders,
          'totalRevenue': stats.todayRevenue.round(),
        };
      });
    } catch (e) {
      // Handle error silently for stats
    }
  }

  // Helper methods for generating display data
  String generateCustomerName(int orderId) {
    final names = ['Nguyễn Văn A', 'Trần Thị B', 'Lê Văn C', 'Phạm Thị D', 'Hoàng Văn E', 'Vũ Thị F'];
    return names[orderId % names.length];
  }
  
  String generatePaymentMethod(int orderId) {
    final methods = ['Tiền mặt', 'Thẻ tín dụng', 'Chuyển khoản', 'Ví điện tử'];
    return methods[orderId % methods.length];
  }
  
  String getProductImageUrl(String productName) {
    // Map product names to actual image URLs
    final imageMap = {
      'Wireless Headphones Pro': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=200',
      'Minimalist Wrist Watch': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=200',
      'Ceramic Breakfast Bowl': 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=200',
      'Áo phông': 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=200',
      'Quần jean': 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=200',
      'Giày thể thao': 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=200',
      'Túi xách': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=200',
      'Đồng hồ': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=200',
      'Smartphone': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=200',
      'Laptop': 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=200',
      'Tai nghe': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=200',
    };
    return imageMap[productName] ?? 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=200';
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    _currentPage++;
    try {
      final orders = await _orderService.getOrders(
        page: _currentPage,
        limit: 20,
        status: _selectedStatus,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _orders.addAll(orders);
        _hasMore = orders.length == 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentPage--;
      });
    }
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(order.id!, newStatus);
      
      setState(() {
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _orders[index] = order.copyWith(status: newStatus);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${order.id} status updated to ${newStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailsDialog(order: order),
    );
  }

  void _onSearch(String value) {
    _searchQuery = value;
    _loadOrders();
  }

  Future<void> _refreshOrders() async {
    await _loadOrders();
    await _loadOrderStats();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF135BEC).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 40,
              color: Color(0xFF135BEC),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedStatus == null ? 'No orders found' : 'No ${_selectedStatus!.displayName.toLowerCase()} orders',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Try adjusting your search or filters' 
                : 'Orders will appear here when customers place them',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterTabs() {
    final statuses = [null, ...OrderStatus.values];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses.map((status) {
            final isSelected = _selectedStatus == status;
            final label = status?.displayName ?? 'All';
            final count = _getStatusCount(status);
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : const Color(0xFF135BEC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF135BEC) : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? status : null;
                  });
                  _loadOrders();
                },
                selectedColor: const Color(0xFF135BEC),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  int _getStatusCount(OrderStatus? status) {
    if (status == null) return _orders.length;
    return _orders.where((order) => order.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Order Management',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Today\'s Orders',
                    '${_orderStats['todayOrders']}',
                    Icons.shopping_bag,
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Revenue',
                    '\$${_orderStats['totalRevenue']}',
                    Icons.attach_money,
                    const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search orders by ID or customer name...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status Filter Tabs
          _buildStatusFilterTabs(),

          const SizedBox(height: 16),

          // Orders List
          Expanded(
            child: _orders.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _refreshOrders,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _orders.length + (_isLoading ? 1 : 0),
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= _orders.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final order = _orders[index];
                        return _buildOrderCard(order);
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNav(currentRoute: AdminOrderManagementScreen.routeName),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF1F2937),
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

  Widget _buildOrderCard(Order order) {
    final customerName = generateCustomerName(order.id!);
    final paymentMethod = generatePaymentMethod(order.id!);
    
    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF135BEC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${order.id}',
                          style: const TextStyle(
                            color: Color(0xFF135BEC),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.status.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<OrderStatus>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF9CA3AF)),
                    itemBuilder: (context) => OrderStatus.values
                        .where((status) => status != order.status)
                        .map((status) => PopupMenuItem(
                              value: status,
                              child: Text('Mark as ${status.displayName}'),
                            ))
                        .toList(),
                    onSelected: (status) => _updateOrderStatus(order, status),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.payment, size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            Text(
                              paymentMethod,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            Text(
                              order.formattedPlacedAt,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    order.formattedTotal,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),

              if (order.items?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF3F4F6), thickness: 1),
                const SizedBox(height: 12),
                
                // Product Items
                ...(order.items?.take(2).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Product Image
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                          image: DecorationImage(
                            image: NetworkImage(getProductImageUrl(item.productName)),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              // Handle image loading error
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Qty: ${item.quantity} × ${item.formattedUnitPrice}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.formattedLineTotal,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                )) ?? []),

                if ((order.items?.length ?? 0) > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${(order.items?.length ?? 0) - 2} more items',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.confirmed:
        return const Color(0xFF3B82F6);
      case OrderStatus.processing:
        return const Color(0xFF8B5CF6);
      case OrderStatus.shipping:
        return const Color(0xFF06B6D4);
      case OrderStatus.delivered:
        return const Color(0xFF10B981);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
      case OrderStatus.refunded:
        return const Color(0xFF6B7280);
    }
  }
}