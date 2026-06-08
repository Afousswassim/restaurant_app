class CartItem {
  final String id;
  final String menuItemId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final String restaurantId;

  CartItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.restaurantId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    String mId = '';
    String mName = json['name']?.toString() ?? '';
    double mPrice = _parseDouble(json['price']);
    String mImageUrl = json['imageUrl']?.toString() ?? '';

    final rawMenuItemId = json['menuItemId'];
    if (rawMenuItemId is Map<String, dynamic>) {
      mId = _parseId(rawMenuItemId['_id'] ?? rawMenuItemId['id']);
      mName = rawMenuItemId['name']?.toString() ?? mName;
      mPrice = _parseDouble(rawMenuItemId['price'] ?? mPrice);
      mImageUrl = rawMenuItemId['imageUrl']?.toString() ?? mImageUrl;
    } else {
      mId = _parseId(rawMenuItemId);
    }

    return CartItem(
      id: _parseId(json['_id'] ?? json['id']),
      menuItemId: mId,
      name: mName,
      price: mPrice,
      imageUrl: mImageUrl,
      quantity: _parseInt(json['quantity']),
      restaurantId: _parseId(json['restaurantId']),
    );
  }

  static String _parseId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      return value['_id']?.toString() ?? value['id']?.toString() ?? '';
    }
    return value.toString();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'menuItemId': menuItemId,
    'name': name,
    'price': price,
    'imageUrl': imageUrl,
    'quantity': quantity,
    'restaurantId': restaurantId,
  };

  double get totalPrice => price * quantity;
}
