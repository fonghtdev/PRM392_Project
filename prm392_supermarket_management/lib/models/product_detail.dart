class ProductDetail {
  final int id;
  final String name;
  final String category;
  final String description;
  final double price;
  final double? originalPrice;
  final int discountPercentage;
  final List<String> imageUrls;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final int availableQuantity;
  final List<ProductFeature> features;

  ProductDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    this.originalPrice,
    this.discountPercentage = 0,
    required this.imageUrls,
    required this.rating,
    required this.reviewCount,
    required this.inStock,
    required this.availableQuantity,
    this.features = const [],
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      originalPrice: json['originalPrice']?.toDouble(),
      discountPercentage: json['discountPercentage'] ?? 0,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      inStock: json['inStock'] ?? false,
      availableQuantity: json['availableQuantity'] ?? 0,
      features: (json['features'] as List<dynamic>?)
          ?.map((f) => ProductFeature.fromJson(f))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'discountPercentage': discountPercentage,
      'imageUrls': imageUrls,
      'rating': rating,
      'reviewCount': reviewCount,
      'inStock': inStock,
      'availableQuantity': availableQuantity,
      'features': features.map((f) => f.toJson()).toList(),
    };
  }

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  
  String get formattedOriginalPrice => originalPrice != null 
      ? '\$${originalPrice!.toStringAsFixed(2)}' 
      : '';

  String get formattedRating => rating.toStringAsFixed(1);

  String get formattedReviewCount {
    if (reviewCount >= 1000) {
      return '${(reviewCount / 1000).toStringAsFixed(1)}k';
    }
    return reviewCount.toString();
  }
}

class ProductFeature {
  final String title;
  final String description;
  final String? icon;

  ProductFeature({
    required this.title,
    required this.description,
    this.icon,
  });

  factory ProductFeature.fromJson(Map<String, dynamic> json) {
    return ProductFeature(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
    };
  }
}