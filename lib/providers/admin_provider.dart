import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class AdminProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _adminInfo;
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get adminInfo => _adminInfo;
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('admin_token')) {
        _token = prefs.getString('admin_token');
        final email = prefs.getString('admin_email');
        final name = prefs.getString('admin_name');
        if (email != null && name != null) {
          _adminInfo = {'email': email, 'name': name};
        }
        notifyListeners();
      }
    } catch (_) {
      // SharedPreferences might fail to init in tests, ignore
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.adminLogin(email, password);
      _token = response['token'];
      _adminInfo = Map<String, dynamic>.from(response['admin']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_token', _token!);
      await prefs.setString('admin_email', _adminInfo!['email'] ?? '');
      await prefs.setString('admin_name', _adminInfo!['name'] ?? '');
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _adminInfo = null;
    _orders = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('admin_token');
      await prefs.remove('admin_email');
      await prefs.remove('admin_name');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await ApiService.getOrders();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedOrder = await ApiService.updateOrderStatus(orderId, newStatus);
      // Update local state list immediately for responsive UI
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      
      // Fetch fresh data in the background to guarantee absolute synchronization
      _fetchOrdersSilent();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _fetchOrdersSilent() async {
    try {
      _orders = await ApiService.getOrders();
      _error = null;
      notifyListeners();
    } catch (_) {
      // Fail silently for background refreshes
    }
  }

  // Statistics
  int get totalOrdersCount => _orders.length;
  int get pendingOrdersCount => _orders.where((o) => o.status == 'pending').length;
  int get preparingOrdersCount => _orders.where((o) => o.status == 'preparing').length;
  int get deliveringOrdersCount => _orders.where((o) => o.status == 'delivering').length;
  int get deliveredOrdersCount => _orders.where((o) => o.status == 'delivered').length;

  double get totalRevenue => _orders.fold<double>(0.0, (sum, order) => sum + order.totalAmount);
}
