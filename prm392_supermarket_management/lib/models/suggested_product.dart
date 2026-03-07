class SuggestedProduct {
  final int id;
  final String name;
  final double price;
  final String imageUrl;

  SuggestedProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  factory SuggestedProduct.fromJson(Map<String, dynamic> json) {
    return SuggestedProduct(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      imageUrl: json['imageUrl'],
    );
  }
}
