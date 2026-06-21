import 'package:flutter/material.dart';
import '../models/branch.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  Branch? _selectedBranch;
  bool _isLoading = false;
  String? _error;

  String? _appliedCouponCode;
  double _couponValue = 0.0;
  String? _discountType;

  List<CartItem> get cartItems => _items;
  List<CartItem> get items => _items;
  Branch? get selectedBranch => _selectedBranch;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get appliedCouponCode => _appliedCouponCode;

  void updateBranch(Branch? branch) {
    _selectedBranch = branch;
    notifyListeners();
  }

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  
  double get deliveryFee {
    if (_discountType == 'free_delivery') return 0.0;
    return _selectedBranch?.deliveryFee ?? 0.0;
  }

  double get couponDiscount {
    if (_appliedCouponCode == null) return 0.0;
    if (_discountType == 'percentage') {
      return double.parse((subtotal * (_couponValue / 100)).toStringAsFixed(2));
    } else if (_discountType == 'fixed') {
      return subtotal < _couponValue ? subtotal : _couponValue;
    }
    return 0.0; // free delivery handled in deliveryFee
  }

  double get total {
    double baseTotal = subtotal + deliveryFee;
    return (baseTotal - couponDiscount).clamp(0.0, double.infinity);
  }

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  Future<void> loadCart() async {
    await SessionManager.ensureSession();
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

  Future<void> addToCart(MenuItem item, Branch branch, int quantity, List<ExtraOption> extras) async {
    await SessionManager.ensureSession();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await ApiService.addToCart(
        sessionId: SessionManager.sessionId,
        menuItemId: item.id,
        branchId: branch.id,
        quantity: quantity,
        selectedExtras: extras,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> increaseQuantity(CartItem cartItem) async {
    await SessionManager.ensureSession();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await ApiService.updateCartItem(
        sessionId: SessionManager.sessionId,
        cartItemId: cartItem.id,
        quantity: cartItem.quantity + 1,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> decreaseQuantity(CartItem cartItem) async {
    await SessionManager.ensureSession();
    if (cartItem.quantity <= 1) {
      await removeItem(cartItem);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await ApiService.updateCartItem(
        sessionId: SessionManager.sessionId,
        cartItemId: cartItem.id,
        quantity: cartItem.quantity - 1,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeItem(CartItem cartItem) async {
    await SessionManager.ensureSession();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await ApiService.removeFromCart(
        sessionId: SessionManager.sessionId,
        cartItemId: cartItem.id,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    await SessionManager.ensureSession();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await ApiService.clearCart(SessionManager.sessionId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyCouponCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.validateCoupon(code, subtotal);
      _appliedCouponCode = res['code'];
      _discountType = res['discountType'];
      _couponValue = (res['value'] ?? 0).toDouble();
      _error = null;
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _discountType = null;
    _couponValue = 0.0;
    notifyListeners();
  }
}
