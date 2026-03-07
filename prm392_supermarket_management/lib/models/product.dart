class Product {
  final int? id;
  final int categoryId;
  final String name;
  final String sku;
  final String? description;
  final double price;
  final int stockQuantity;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.categoryId,
    required this.name,
    required this.sku,
    this.description,
    required this.price,
    this.stockQuantity = 0,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert from Map (database)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toInt(),
      categoryId: map['category_id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      description: map['description'],
      price: map['price']?.toDouble() ?? 0.0,
      stockQuantity: map['stock_quantity']?.toInt() ?? 0,
      imageUrl: map['image_url'],
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
    );
  }

  // Convert to Map (for database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'sku': sku,
      'description': description,
      'price': price,
      'stock_quantity': stockQuantity,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'sku': sku,
      'description': description,
      'price': price,
      'stockQuantity': stockQuantity,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toInt(),
      categoryId: json['categoryId']?.toInt() ?? 0,
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      description: json['description'],
      price: json['price']?.toDouble() ?? 0.0,
      stockQuantity: json['stockQuantity']?.toInt() ?? 0,
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  // Copy with method for updates
  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? sku,
    String? description,
    double? price,
    int? stockQuantity,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isInStock => stockQuantity > 0;
  bool get isOutOfStock => stockQuantity <= 0;
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 5;

  // Stock status as string
  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  // Formatted price
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  @override
  String toString() {
    return 'Product{id: $id, name: $name, sku: $sku, price: $price, stock: $stockQuantity}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id && other.sku == sku;
  }

  @override
  int get hashCode => id.hashCode ^ sku.hashCode;
}