class ProductModel {
  final String id;
  final String name;
  final String? brand;
  final String? barcode;
  final String status; // 'halal' | 'haram' | 'doubtful'
  final String? reason;
  final List<String>? ingredients;
  final String? imageUrl;
  final String? category;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    this.brand,
    this.barcode,
    required this.status,
    this.reason,
    this.ingredients,
    this.imageUrl,
    this.category,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      brand: json['brand'],
      barcode: json['barcode'],
      status: json['status'] ?? 'doubtful',
      reason: json['reason'],
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : null,
      imageUrl: json['image_url'],
      category: json['category'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'barcode': barcode,
      'status': status,
      'reason': reason,
      'ingredients': ingredients,
      'image_url': imageUrl,
      'category': category,
    };
  }

  bool get isHalal => status == 'halal';
  bool get isHaram => status == 'haram';
  bool get isDoubtful => status == 'doubtful';
}
