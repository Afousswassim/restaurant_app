import 'package:flutter/material.dart';
import '../models/branch.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../utils/helpers.dart';

class OrderProvider with ChangeNotifier {
  Order? _currentOrder;
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  Order? get currentOrder => _currentOrder;
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> createOrder({
    required String customerName,
    required String phone,
    required String address,
    required Branch branch,
    String? paymentMethod,
    String? notes,
    String? clientId,
    double? discount,
    String? couponCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SessionManager.ensureSession();
      final order = await ApiService.createOrder(
        sessionId: SessionManager.sessionId,
        customerName: customerName,
        phone: phone,
        address: address,
        branch: branch,
        paymentMethod: paymentMethod,
        notes: notes,
        clientId: clientId,
        discount: discount,
        couponCode: couponCode,
      );
      _currentOrder = order;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentOrder = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await ApiService.getOrder(orderId);
      _currentOrder = order;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await ApiService.getAllOrders();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }
}
