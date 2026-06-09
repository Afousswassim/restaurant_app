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
  final String imageUrl;
  final String category;
  final List<ExtraOption> extras;
  final bool isAvailable;

  MenuItem({
    required this.id,
    this.branchId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.extras,
    this.isAvailable = true,
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
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      extras: parsedExtras,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'branchId': branchId,
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'category': category,
    'extras': extras.map((e) => e.toJson()).toList(),
    'isAvailable': isAvailable,
  };
}
