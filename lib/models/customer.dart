class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String avatar;
  final String status;
  final int rewardPoints;
  final int totalOrders;
  final double totalSpent;
  final String favoriteCategory;
  final String favoriteProduct;
  final DateTime? lastOrder;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.avatar,
    required this.status,
    required this.rewardPoints,
    required this.totalOrders,
    required this.totalSpent,
    required this.favoriteCategory,
    required this.favoriteProduct,
    this.lastOrder,
    this.createdAt,
    this.lastLogin,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return Customer(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['fullName'] ?? json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      avatar: json['avatar'] ?? '',
      status: json['status'] ?? 'Active',
      rewardPoints: json['loyaltyPoints'] ?? json['rewardPoints'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      favoriteCategory: json['favoriteCategory'] ?? '',
      favoriteProduct: json['favoriteProduct'] ?? '',
      lastOrder: parseDate(json['lastOrder']),
      createdAt: parseDate(json['createdAt']),
      lastLogin: parseDate(json['lastLogin'] ?? json['lastLoginAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'fullName': name,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'avatar': avatar,
      'status': status,
      'loyaltyPoints': rewardPoints,
      'rewardPoints': rewardPoints,
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'favoriteCategory': favoriteCategory,
      'favoriteProduct': favoriteProduct,
      'lastOrder': lastOrder?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? avatar,
    String? status,
    int? rewardPoints,
    int? totalOrders,
    double? totalSpent,
    String? favoriteCategory,
    String? favoriteProduct,
    DateTime? lastOrder,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      favoriteCategory: favoriteCategory ?? this.favoriteCategory,
      favoriteProduct: favoriteProduct ?? this.favoriteProduct,
      lastOrder: lastOrder ?? this.lastOrder,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
