import 'branch.dart';
import 'menu_item.dart';

class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double price; // Note: this is finalPrice for backward compatibility
  final double originalPrice;
  final double finalPrice;
  final bool offerApplied;
  final List<ExtraOption> selectedExtras;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
    this.originalPrice = 0.0,
    this.finalPrice = 0.0,
    this.offerApplied = false,
    required this.selectedExtras,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    var rawExtras = json['selectedExtras'] as List<dynamic>?;
    List<ExtraOption> parsedExtras = rawExtras != null
        ? rawExtras.map((e) => ExtraOption.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    return OrderItem(
      menuItemId: json['menuItemId'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: (json['originalPrice'] ?? json['price'] ?? 0).toDouble(),
      finalPrice: (json['finalPrice'] ?? json['price'] ?? 0).toDouble(),
      offerApplied: json['offerApplied'] ?? false,
      selectedExtras: parsedExtras,
    );
  }

  Map<String, dynamic> toJson() => {
    'menuItemId': menuItemId,
    'name': name,
    'quantity': quantity,
    'price': price,
    'originalPrice': originalPrice,
    'finalPrice': finalPrice,
    'offerApplied': offerApplied,
    'selectedExtras': selectedExtras.map((e) => e.toJson()).toList(),
  };

  double get unitPrice {
    double extrasPrice = selectedExtras.fold(0.0, (sum, extra) => sum + extra.price);
    return price + extrasPrice;
  }

  double get totalPrice => unitPrice * quantity;
}

class Order {
  final String id;
  final String customerName;
  final String phone;
  final String address;
  final Branch branch;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String notes;
  final String? clientId;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.branch,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.notes,
    required this.createdAt,
    this.clientId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>?;
    List<OrderItem> parsedItems = rawItems != null
        ? rawItems.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      customerName: json['customerName'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      branch: Branch.fromJson(json['branch'] ?? {}),
      items: parsedItems,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'cash',
      notes: json['notes'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      clientId: json['clientId'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'customerName': customerName,
    'phone': phone,
    'address': address,
    'branch': branch.toJson(),
    'items': items.map((e) => e.toJson()).toList(),
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'totalAmount': totalAmount,
    'status': status,
    'paymentMethod': paymentMethod,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'clientId': clientId,
  };

  String get statusDisplay {
    switch (status) {
      case 'confirmed':
        return 'Order Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'delivering':
        return 'Delivering';
      case 'on-way':
        return 'On The Way';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }
}
