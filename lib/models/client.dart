class Client {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final String landmark;

  Client({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
    required this.landmark,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      landmark: json['landmark'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'fullName': fullName,
    'phone': phone,
    'email': email,
    'address': address,
    'landmark': landmark,
  };
}
