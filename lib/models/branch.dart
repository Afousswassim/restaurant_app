class Branch {
  final String id;
  final String slug;
  final String name;
  final String address;
  final double deliveryFee;
  final String deliveryTime;
  final String qrUrl;
  final String city;
  final String phone;
  final String openingHours;

  Branch({
    required this.id,
    required this.slug,
    required this.name,
    required this.address,
    required this.deliveryFee,
    required this.deliveryTime,
    this.qrUrl = '',
    this.city = '',
    this.phone = '',
    this.openingHours = '',
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id'] ?? json['id'] ?? '',
      slug: json['slug'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      deliveryTime: json['deliveryTime'] ?? '',
      qrUrl: json['qrUrl'] ?? '',
      city: json['city'] ?? '',
      phone: json['phone'] ?? '',
      openingHours: json['openingHours'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'slug': slug,
    'name': name,
    'address': address,
    'deliveryFee': deliveryFee,
    'deliveryTime': deliveryTime,
    'qrUrl': qrUrl,
    'city': city,
    'phone': phone,
    'openingHours': openingHours,
  };
}
