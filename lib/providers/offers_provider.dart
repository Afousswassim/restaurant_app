import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';

class OffersProvider with ChangeNotifier {
  List<MenuItem> _offers = [];
  bool _isLoading = false;
  String? _error;

  List<MenuItem> get offers => _offers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  OffersProvider() {
    loadOffers();
  }

  Future<void> loadOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final items = await ApiService.getActiveOffers();
      _offers = items.where((item) => item.isCurrentlyActiveOffer).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _offers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
