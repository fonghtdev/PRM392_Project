import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../app_bottom_nav.dart';

class AdminProductManagementScreen extends StatefulWidget {
  const AdminProductManagementScreen({super.key});
  static const routeName = '/admin/products';

  @override
  State<AdminProductManagementScreen> createState() => _AdminProductManagementScreenState();
}

class _AdminProductManagementScreenState extends State<AdminProductManagementScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  
  // Categories for filtering
  final List<String> _categories = ['All', 'Electronics', 'Apparel', 'Accessories', 'Home & Garden', 'Sports'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterProducts();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreData) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.getAllProducts();
      setState(() {
        _products = products;
        _filterProducts();
      });
    } catch (e) {
      _showErrorSnackBar('Lỗi khi tải danh sách sản phẩm: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      _currentPage++;
      final newProducts = await _productService.getProductsPaginated(
        page: _currentPage,
        pageSize: _pageSize,
        searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
      );
      
      if (newProducts.length < _pageSize) {
        _hasMoreData = false;
      }
      
      setState(() {
        _products.addAll(newProducts);
        _filterProducts();
      });
    } catch (e) {
      _currentPage--;
      _showErrorSnackBar('Lỗi khi tải thêm sản phẩm: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = _searchController.text.isEmpty ||
            product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            product.sku.toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'All' || 
            product.categoryId == _getCategoryId(_selectedCategory);
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  int _getCategoryId(String categoryName) {
    switch (categoryName) {
      case 'Electronics': return 1;
      case 'Apparel': return 2;
      case 'Accessories': return 3;
      case 'Home & Garden': return 4;
      case 'Sports': return 5;
      default: return 1;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showAddProductDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddProductDialog(),
    );
    
    if (result == true) {
      _loadProducts();
      _showSuccessSnackBar('Thêm sản phẩm thành công!');
    }
  }

  Future<void> _showEditProductDialog(Product product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditProductDialog(product: product),
    );
    
    if (result == true) {
      _loadProducts();
      _showSuccessSnackBar('Cập nhật sản phẩm thành công!');
    }
  }

  Future<void> _showStockDialog(Product product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StockManagementDialog(product: product),
    );
    
    if (result == true) {
      _loadProducts();
      _showSuccessSnackBar('Cập nhật tồn kho thành công!');
    }
  }

  Color _getStockStatusColor(Product product) {
    if (product.stockQuantity == 0) {
      return Colors.red;
    } else if (product.stockQuantity <= 5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStockStatusText(Product product) {
    if (product.stockQuantity == 0) {
      return 'Out of Stock';
    } else if (product.stockQuantity <= 5) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color(0xFFF6F6F8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.menu, color: Color(0xFF1F2937)),
                  ),
                  const Expanded(
                    child: Text(
                      'Product Inventory',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF135BEC),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _showAddProductDialog,
                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search products, SKU or tags...',
                    hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Filter Chips
            SizedBox(
              height: 36,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _filterProducts();
                        });
                      },
                      backgroundColor: const Color(0xFFE2E8F0).withOpacity(0.5),
                      selectedColor: const Color(0xFF135BEC),
                      checkmarkColor: Colors.white,
                      elevation: 0,
                      pressElevation: 0,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Product List
            Expanded(
              child: _isLoading && _products.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF135BEC)))
                  : _filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'Không tìm thấy sản phẩm nào',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _filteredProducts.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredProducts.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator(color: Color(0xFF135BEC))),
                              );
                            }
                            
                            final product = _filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentRoute: AdminProductManagementScreen.routeName),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              image: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(product.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.imageUrl == null || product.imageUrl!.isEmpty
                ? const Icon(Icons.image, color: Color(0xFF94A3B8), size: 32)
                : null,
          ),
          
          const SizedBox(width: 16),
          
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStockStatusColor(product).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStockStatusText(product),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStockStatusColor(product),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Text(
                      'Qty: ${product.stockQuantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF135BEC),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Action Buttons
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: IconButton(
                        onPressed: () => _showStockDialog(product),
                        icon: const Icon(Icons.inventory_2, size: 16, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: IconButton(
                        onPressed: () => _showEditProductDialog(product),
                        icon: const Icon(Icons.edit, size: 16, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add Product Dialog
class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final ProductService _productService = ProductService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _skuController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  int _selectedCategoryId = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _productService.createProduct(
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        sku: _skuController.text,
        categoryId: _selectedCategoryId,
        stockQuantity: int.parse(_stockController.text),
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      );
      
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm Sản Phẩm Mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm *'),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập tên sản phẩm' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả *'),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập mô tả' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá *'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập giá';
                  final price = double.tryParse(value!);
                  if (price == null || price < 0) return 'Giá không hợp lệ';
                  return null;
                },
              ),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU *'),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập SKU' : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Số lượng tồn kho *'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập số lượng';
                  final stock = int.tryParse(value!);
                  if (stock == null || stock < 0) return 'Số lượng không hợp lệ';
                  return null;
                },
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'URL hình ảnh'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createProduct,
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Tạo'),
        ),
      ],
    );
  }
}

// Edit Product Dialog
class EditProductDialog extends StatefulWidget {
  final Product product;
  
  const EditProductDialog({super.key, required this.product});

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final ProductService _productService = ProductService();
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _skuController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageUrlController;
  
  late int _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _skuController = TextEditingController(text: widget.product.sku);
    _stockController = TextEditingController(text: widget.product.stockQuantity.toString());
    _imageUrlController = TextEditingController(text: widget.product.imageUrl ?? '');
    _selectedCategoryId = widget.product.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _productService.updateProduct(
        widget.product,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        sku: _skuController.text,
        categoryId: _selectedCategoryId,
        stockQuantity: int.parse(_stockController.text),
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      );
      
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh Sửa Sản Phẩm'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm *'),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập tên sản phẩm' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả *'),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập mô tả' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá *'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập giá';
                  final price = double.tryParse(value!);
                  if (price == null || price < 0) return 'Giá không hợp lệ';
                  return null;
                },
              ),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU *'),
                validator: (value) => value?.isEmpty ?? true ? 'Vui lòng nhập SKU' : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Số lượng tồn kho *'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập số lượng';
                  final stock = int.tryParse(value!);
                  if (stock == null || stock < 0) return 'Số lượng không hợp lệ';
                  return null;
                },
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'URL hình ảnh'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateProduct,
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Cập nhật'),
        ),
      ],
    );
  }
}

// Stock Management Dialog
class StockManagementDialog extends StatefulWidget {
  final Product product;
  
  const StockManagementDialog({super.key, required this.product});

  @override
  State<StockManagementDialog> createState() => _StockManagementDialogState();
}

class _StockManagementDialogState extends State<StockManagementDialog> {
  final ProductService _productService = ProductService();
  final _quantityController = TextEditingController();
  
  bool _isAdding = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _updateStock() async {
    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số lượng hợp lệ'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isAdding) {
        await _productService.restockProduct(widget.product.id!, quantity);
      } else {
        final success = await _productService.sellProduct(widget.product.id!, quantity);
        if (!success) {
          throw Exception('Không đủ hàng trong kho');
        }
      }
      
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Quản Lý Kho - ${widget.product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Tồn kho hiện tại: ${widget.product.stockQuantity}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Nhập kho'),
                  value: true,
                  groupValue: _isAdding,
                  onChanged: (value) => setState(() => _isAdding = value!),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Xuất kho'),
                  value: false,
                  groupValue: _isAdding,
                  onChanged: (value) => setState(() => _isAdding = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Số lượng',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateStock,
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isAdding ? 'Nhập kho' : 'Xuất kho'),
        ),
      ],
    );
  }
}
