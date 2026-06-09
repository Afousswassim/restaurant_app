import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';

class MenuProvider with ChangeNotifier {
  List<MenuItem> _menuItems = [];
  String _selectedCategory = 'Burger'; // Default to first category 'Burger'
  bool _isLoading = false;
  String? _error;

  List<MenuItem> get menuItems {
    if (_selectedCategory == 'All') {
      return _menuItems;
    }
    return _menuItems
        .where((item) => item.category.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  List<MenuItem> get rawMenuItems => _menuItems;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMenu(String? branchId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (branchId != null && branchId.isNotEmpty) {
        _menuItems = await ApiService.getMenuByBranch(branchId);
      } else {
        _menuItems = await ApiService.getMenu();
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      _menuItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
