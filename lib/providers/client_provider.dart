import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/client.dart';
import '../services/api_service.dart';

class ClientProvider with ChangeNotifier {
  Client? _currentClient;
  String? _token;
  bool _isLoading = false;
  String? _error;

  Client? get currentClient => _currentClient;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ClientProvider() {
    loadSession();
  }

  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('client_token')) {
        _token = prefs.getString('client_token');
        final clientJson = prefs.getString('client_info');
        if (clientJson != null) {
          _currentClient = Client.fromJson(jsonDecode(clientJson));
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.registerClient(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
      );
      _token = data['token'];
      _currentClient = Client.fromJson(data['client']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('client_token', _token!);
      await prefs.setString('client_info', jsonEncode(_currentClient!.toJson()));

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

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.loginClient(
        email: email,
        password: password,
      );
      _token = data['token'];
      _currentClient = Client.fromJson(data['client']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('client_token', _token!);
      await prefs.setString('client_info', jsonEncode(_currentClient!.toJson()));

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
    _currentClient = null;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('client_token');
    await prefs.remove('client_info');
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? landmark,
  }) async {
    if (_token == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedClientData = await ApiService.updateClientProfile(
        token: _token!,
        fullName: fullName,
        phone: phone,
        address: address,
        landmark: landmark,
      );
      _currentClient = Client.fromJson(updatedClientData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('client_info', jsonEncode(_currentClient!.toJson()));

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
}
