class Product {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final bool isActive;
  final double? averageRating;
  final int? numReviews;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.images = const [],
    this.isActive = true,
    this.averageRating,
    this.numReviews,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle vendor field - can be either a String (ID) or populated object
    String vendorId = '';
    if (json['vendor'] is String) {
      vendorId = json['vendor'];
    } else if (json['vendor'] is Map) {
      // If vendor is populated, extract the _id
      vendorId = json['vendor']['_id'] ?? '';
    }

    return Product(
      id: json['_id'] ?? '',
      vendorId: vendorId,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      isActive: json['isActive'] ?? true,
      averageRating: json['averageRating']?.toDouble(),
      numReviews: json['numReviews'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'vendor': vendorId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'isActive': isActive,
      'averageRating': averageRating,
      'numReviews': numReviews,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    double? price,
    String? category,
    List<String>? images,
    bool? isActive,
    double? averageRating,
    int? numReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      images: images ?? this.images,
      isActive: isActive ?? this.isActive,
      averageRating: averageRating ?? this.averageRating,
      numReviews: numReviews ?? this.numReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
