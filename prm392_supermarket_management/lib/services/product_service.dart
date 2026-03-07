import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final ProductRepository _repository = ProductRepository();

  // Create new product
  Future<Product> createProduct({
    required String name,
    required String description,
    required double price,
    required String sku,
    int categoryId = 1,
    int stockQuantity = 0,
    String? imageUrl,
  }) async {
    // Validate SKU uniqueness
    final isUnique = await _repository.isSkuUnique(sku);
    if (!isUnique) {
      throw Exception('SKU đã tồn tại. Vui lòng chọn SKU khác.');
    }

    // Validate price
    if (price < 0) {
      throw Exception('Giá sản phẩm không thể âm.');
    }

    // Validate stock quantity
    if (stockQuantity < 0) {
      throw Exception('Số lượng tồn kho không thể âm.');
    }

    final product = Product(
      id: 0, // Will be auto-generated
      name: name.trim(),
      description: description.trim(),
      price: price,
      sku: sku.trim().toUpperCase(),
      categoryId: categoryId,
      stockQuantity: stockQuantity,
      imageUrl: imageUrl?.trim(),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final productId = await _repository.createProduct(product);
    final createdProduct = await _repository.getProductById(productId);
    
    if (createdProduct == null) {
      throw Exception('Không thể tạo sản phẩm.');
    }
    
    return createdProduct;
  }

  // Get all active products
  Future<List<Product>> getActiveProducts() async {
    return await _repository.getActiveProducts();
  }

  // Get all products (admin only)
  Future<List<Product>> getAllProducts() async {
    return await _repository.getAllProducts();
  }

  // Get product by ID
  Future<Product?> getProductById(int id) async {
    return await _repository.getProductById(id);
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    return await _repository.getProductsByCategory(categoryId);
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      return await getActiveProducts();
    }
    return await _repository.searchProducts(query.trim());
  }

  // Get products with pagination
  Future<List<Product>> getProductsPaginated({
    int page = 0,
    int pageSize = 20,
    int? categoryId,
    String? searchQuery,
  }) async {
    return await _repository.getProductsPaginated(
      page: page,
      pageSize: pageSize,
      categoryId: categoryId,
      searchQuery: searchQuery?.trim(),
    );
  }

  // Update product
  Future<Product> updateProduct(Product product, {
    String? name,
    String? description,
    double? price,
    String? sku,
    int? categoryId,
    int? stockQuantity,
    String? imageUrl,
    bool? isActive,
  }) async {
    // Validate SKU if changed
    if (sku != null && sku != product.sku) {
      final isUnique = await _repository.isSkuUnique(sku, excludeProductId: product.id);
      if (!isUnique) {
        throw Exception('SKU đã tồn tại. Vui lòng chọn SKU khác.');
      }
    }

    // Validate price
    if (price != null && price < 0) {
      throw Exception('Giá sản phẩm không thể âm.');
    }

    // Validate stock quantity
    if (stockQuantity != null && stockQuantity < 0) {
      throw Exception('Số lượng tồn kho không thể âm.');
    }

    final updatedProduct = product.copyWith(
      name: name?.trim(),
      description: description?.trim(),
      price: price,
      sku: sku?.trim().toUpperCase(),
      categoryId: categoryId,
      stockQuantity: stockQuantity,
      imageUrl: imageUrl?.trim(),
      isActive: isActive,
      updatedAt: DateTime.now(),
    );

    await _repository.updateProduct(updatedProduct);
    
    final result = await _repository.getProductById(product.id!);
    if (result == null) {
      throw Exception('Không thể cập nhật sản phẩm.');
    }
    
    return result;
  }

  // Stock management
  Future<bool> updateStock(int productId, int newQuantity) async {
    if (newQuantity < 0) {
      throw Exception('Số lượng tồn kho không thể âm.');
    }

    final product = await _repository.getProductById(productId);
    if (product == null) {
      throw Exception('Không tìm thấy sản phẩm.');
    }

    final result = await _repository.updateStock(productId, newQuantity);
    return result > 0;
  }

  // Decrease stock when selling
  Future<bool> sellProduct(int productId, int quantity) async {
    if (quantity <= 0) {
      throw Exception('Số lượng bán phải lớn hơn 0.');
    }

    final product = await _repository.getProductById(productId);
    if (product == null) {
      throw Exception('Không tìm thấy sản phẩm.');
    }

    if (!product.isActive) {
      throw Exception('Sản phẩm đã bị vô hiệu hóa.');
    }

    if (product.stockQuantity < quantity) {
      throw Exception('Không đủ hàng trong kho. Còn lại: ${product.stockQuantity}');
    }

    return await _repository.decreaseStock(productId, quantity);
  }

  // Increase stock when restocking
  Future<bool> restockProduct(int productId, int quantity) async {
    if (quantity <= 0) {
      throw Exception('Số lượng nhập phải lớn hơn 0.');
    }

    final product = await _repository.getProductById(productId);
    if (product == null) {
      throw Exception('Không tìm thấy sản phẩm.');
    }

    final result = await _repository.increaseStock(productId, quantity);
    return result > 0;
  }

  // Product status management
  Future<bool> activateProduct(int productId) async {
    final result = await _repository.activateProduct(productId);
    return result > 0;
  }

  Future<bool> deactivateProduct(int productId) async {
    final result = await _repository.deactivateProduct(productId);
    return result > 0;
  }

  Future<bool> deleteProduct(int productId) async {
    final product = await _repository.getProductById(productId);
    if (product == null) {
      throw Exception('Không tìm thấy sản phẩm.');
    }

    final result = await _repository.deleteProduct(productId);
    return result > 0;
  }

  // Inventory alerts
  Future<List<Product>> getLowStockProducts({int threshold = 5}) async {
    return await _repository.getLowStockProducts(threshold: threshold);
  }

  Future<List<Product>> getOutOfStockProducts() async {
    return await _repository.getOutOfStockProducts();
  }

  // Statistics
  Future<Map<String, dynamic>> getProductStatistics() async {
    final stats = await _repository.getProductStats();
    final lowStockProducts = await getLowStockProducts();
    
    return {
      'totalProducts': stats['total'],
      'outOfStock': stats['outOfStock'],
      'lowStock': stats['lowStock'],
      'lowStockProducts': lowStockProducts,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  // Validation helpers
  bool isValidSku(String sku) {
    return sku.trim().isNotEmpty && sku.trim().length >= 3;
  }

  bool isValidPrice(double price) {
    return price >= 0;
  }

  bool isValidStockQuantity(int quantity) {
    return quantity >= 0;
  }

  String generateSku(String productName) {
    final words = productName.trim().toUpperCase().split(' ');
    String sku = '';
    
    for (String word in words) {
      if (word.isNotEmpty) {
        sku += word.substring(0, word.length > 3 ? 3 : word.length);
      }
    }
    
    // Add timestamp to ensure uniqueness
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    sku += timestamp.substring(timestamp.length - 4);
    
    return sku;
  }

  // Bulk operations
  Future<List<Product>> createMultipleProducts(List<Map<String, dynamic>> productsData) async {
    final List<Product> createdProducts = [];
    
    for (var productData in productsData) {
      try {
        final product = await createProduct(
          name: productData['name'],
          description: productData['description'],
          price: productData['price'].toDouble(),
          sku: productData['sku'],
          categoryId: productData['categoryId'] ?? 1,
          stockQuantity: productData['stockQuantity'] ?? 0,
          imageUrl: productData['imageUrl'],
        );
        createdProducts.add(product);
      } catch (e) {
        // Log error but continue with other products
        print('Error creating product ${productData['name']}: $e');
      }
    }
    
    return createdProducts;
  }

  Future<int> bulkUpdateStock(Map<int, int> stockUpdates) async {
    int successCount = 0;
    
    for (var entry in stockUpdates.entries) {
      try {
        await updateStock(entry.key, entry.value);
        successCount++;
      } catch (e) {
        print('Error updating stock for product ${entry.key}: $e');
      }
    }
    
    return successCount;
  }

  // Product availability check
  Future<bool> isProductAvailable(int productId, int requestedQuantity) async {
    final product = await _repository.getProductById(productId);
    
    if (product == null || !product.isActive) {
      return false;
    }
    
    return product.stockQuantity >= requestedQuantity;
  }

  // Get featured products (for home screen)
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    final products = await _repository.getActiveProducts();
    
    // Sort by stock quantity (higher stock = more featured) and take limit
    products.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
    
    return products.take(limit).toList();
  }
}