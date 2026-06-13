class Branch {
  final String id;
  final String slug;
  final String name;
  final String address;
  final double deliveryFee;
  final String deliveryTime;

  Branch({
    required this.id,
    required this.slug,
    required this.name,
    required this.address,
    required this.deliveryFee,
    required this.deliveryTime,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id'] ?? json['id'] ?? '',
      slug: json['slug'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      deliveryTime: json['deliveryTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'slug': slug,
    'name': name,
    'address': address,
    'deliveryFee': deliveryFee,
    'deliveryTime': deliveryTime,
  };
}
