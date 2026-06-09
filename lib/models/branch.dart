class Branch {
  final String id;
  final String name;
  final String address;
  final double deliveryFee;
  final String deliveryTime;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.deliveryFee,
    required this.deliveryTime,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      deliveryTime: json['deliveryTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'address': address,
    'deliveryFee': deliveryFee,
    'deliveryTime': deliveryTime,
  };
}
