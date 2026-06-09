import 'menu_item.dart';

class CartItem {
  final String id;
  final MenuItem menuItem;
  final String branchId;
  final int quantity;
  final List<ExtraOption> selectedExtras;

  CartItem({
    required this.id,
    required this.menuItem,
    required this.branchId,
    required this.quantity,
    required this.selectedExtras,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    var rawExtras = json['selectedExtras'] as List<dynamic>?;
    List<ExtraOption> parsedExtras = rawExtras != null
        ? rawExtras.map((e) => ExtraOption.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    return CartItem(
      id: json['_id'] ?? json['id'] ?? '',
      menuItem: MenuItem.fromJson(json['menuItemId'] ?? {}),
      branchId: json['branchId'] ?? '',
      quantity: json['quantity'] ?? 1,
      selectedExtras: parsedExtras,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'menuItemId': menuItem.toJson(),
    'branchId': branchId,
    'quantity': quantity,
    'selectedExtras': selectedExtras.map((e) => e.toJson()).toList(),
  };

  double get unitPrice {
    double extrasPrice = selectedExtras.fold(0.0, (sum, extra) => sum + extra.price);
    return menuItem.price + extrasPrice;
  }

  double get totalPrice => unitPrice * quantity;
}
