class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final String icon;
  final String status;
  final int sortOrder;

  // Aggregated Stats
  final int productCount;
  final int totalSales;
  final double revenue;
  final double averageRating;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.image = '',
    this.icon = 'fastfood',
    this.status = 'Active',
    this.sortOrder = 0,
    this.productCount = 0,
    this.totalSales = 0,
    this.revenue = 0.0,
    this.averageRating = 0.0,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      icon: json['icon'] ?? 'fastfood',
      status: json['status'] ?? 'Active',
      sortOrder: json['sortOrder'] ?? 0,
      productCount: json['productCount'] ?? 0,
      totalSales: json['totalSales'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'icon': icon,
      'status': status,
      'sortOrder': sortOrder,
    };
  }
}
