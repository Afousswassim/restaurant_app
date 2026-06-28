class ExtraOption {
  final String name;
  final double price;

  ExtraOption({
    required this.name,
    required this.price,
  });

  factory ExtraOption.fromJson(Map<String, dynamic> json) {
    return ExtraOption(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtraOption &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          price == other.price;

  @override
  int get hashCode => name.hashCode ^ price.hashCode;
}

class MenuItem {
  final String id;
  final String? branchId;
  final String name;
  final String description;
  final double price;
  final bool hasOffer;
  final double? oldPrice;
  final double? offerPrice;
  final DateTime? offerExpiresAt;
  final String? offerLabel;
  final String imageUrl;
  final String category;
  final List<ExtraOption> extras;
  final bool isAvailable;
  final double rating;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<String> tags;

  MenuItem({
    required this.id,
    this.branchId,
    required this.name,
    required this.description,
    required this.price,
    this.hasOffer = false,
    this.oldPrice,
    this.offerPrice,
    this.offerExpiresAt,
    this.offerLabel,
    required this.imageUrl,
    required this.category,
    required this.extras,
    this.isAvailable = true,
    this.rating = 4.8,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.tags = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    var rawExtras = json['extras'] as List<dynamic>?;
    List<ExtraOption> parsedExtras = rawExtras != null
        ? rawExtras.map((e) => ExtraOption.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    return MenuItem(
      id: json['_id'] ?? json['id'] ?? '',
      branchId: json['branchId'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      hasOffer: json['hasOffer'] ?? false,
      oldPrice: json['oldPrice'] != null ? (json['oldPrice'] as num).toDouble() : null,
      offerPrice: json['offerPrice'] != null ? (json['offerPrice'] as num).toDouble() : null,
      offerExpiresAt: json['offerExpiresAt'] != null ? DateTime.tryParse(json['offerExpiresAt']) : null,
      offerLabel: json['offerLabel'],
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      extras: parsedExtras,
      isAvailable: json['isAvailable'] ?? true,
      rating: (json['rating'] ?? 4.8).toDouble(),
      calories: (json['calories'] ?? 0).toInt(),
      protein: (json['protein'] ?? 0).toInt(),
      carbs: (json['carbs'] ?? 0).toInt(),
      fat: (json['fat'] ?? 0).toInt(),
      tags: (json['tags'] as List<dynamic>?)?.map((tag) => tag.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'branchId': branchId,
    'name': name,
    'description': description,
    'price': price,
    'hasOffer': hasOffer,
    'oldPrice': oldPrice,
    'offerPrice': offerPrice,
    'offerExpiresAt': offerExpiresAt?.toIso8601String(),
    'offerLabel': offerLabel,
    'imageUrl': imageUrl,
    'category': category,
    'extras': extras.map((e) => e.toJson()).toList(),
    'isAvailable': isAvailable,
    'rating': rating,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'tags': tags,
  };

  double get effectivePrice {
    if (hasOffer && offerPrice != null) {
      if (offerExpiresAt != null && DateTime.now().isAfter(offerExpiresAt!)) {
        return price;
      }
      return offerPrice!;
    }
    return price;
  }
}
