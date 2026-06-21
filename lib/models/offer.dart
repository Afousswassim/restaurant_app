class Offer {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double discountPercentage;
  final double oldPrice;
  final double newPrice;
  final DateTime expiresAt;
  final String? couponCode;
  final bool isFeatured;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.discountPercentage,
    required this.oldPrice,
    required this.newPrice,
    required this.expiresAt,
    this.couponCode,
    this.isFeatured = false,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
      oldPrice: (json['oldPrice'] ?? 0).toDouble(),
      newPrice: (json['newPrice'] ?? 0).toDouble(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now().add(const Duration(hours: 24)),
      couponCode: json['couponCode'],
      isFeatured: json['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'discountPercentage': discountPercentage,
    'oldPrice': oldPrice,
    'newPrice': newPrice,
    'expiresAt': expiresAt.toIso8601String(),
    'couponCode': couponCode,
    'isFeatured': isFeatured,
  };
}
