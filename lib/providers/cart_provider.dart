import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get totalAmount => subtotal + 15;

  String? get restaurantId => _items.isEmpty ? null : _items.first.restaurantId;

  Future<void> initializeCart() async {
    await SessionManager.ensureSession();
    await loadCart();
  }

  Future<void> loadCart() async {
    await SessionManager.ensureSession();
    await fetchCart();
  }

  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await ApiService.getCart(SessionManager.sessionId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart({
    required MenuItem menuItem,
    required String restaurantId,
    int quantity = 1,
  }) async {
    await SessionManager.ensureSession();
    _error = null;

    try {
      await ApiService.addToCart(
        sessionId: SessionManager.sessionId,
        menuItemId: menuItem.id,
        quantity: quantity,
        restaurantId: restaurantId,
      );
      await fetchCart();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateQuantity(String menuItemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(menuItemId);
      return;
    }
    _error = null;
    try {
      await ApiService.updateCartItem(
        sessionId: SessionManager.sessionId,
        menuItemId: menuItemId,
        quantity: quantity,
      );
      await fetchCart();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeItem(String menuItemId) async {
    _error = null;
    try {
      await ApiService.removeFromCart(
        sessionId: SessionManager.sessionId,
        menuItemId: menuItemId,
      );
      await fetchCart();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _error = null;
    try {
      await ApiService.clearCart(SessionManager.sessionId);
      await fetchCart();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool hasRestaurantItems(String restaurantId) {
    return _items.isEmpty || _items.first.restaurantId == restaurantId;
  }
}
