class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    required this.imageUrl,
    this.brand,
    this.description,
    this.category,
    this.exclusive = false,
  });

  final String id;
  final String title;
  final String? brand;
  final String? description;
  final num price;
  final String currency;
  final String? category;
  final String imageUrl;
  final bool exclusive;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      title: json['title'] as String,
      brand: json['brand'] as String?,
      description: json['description'] as String?,
      price: json['price'] as num,
      currency: json['currency'] as String? ?? 'KZT',
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String,
      exclusive: json['exclusive'] as bool? ?? false,
    );
  }
}
