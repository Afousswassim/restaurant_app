import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/api_service.dart';

class MenuProvider with ChangeNotifier {
  List<MenuItem> _menuItems = [];
  String _selectedCategory = 'All'; // Default to show all categories
  String _searchTerm = '';
  bool _isLoading = false;
  String? _error;

  List<MenuItem> get menuItems {
    // Start from all items
    List<MenuItem> items = List<MenuItem>.from(_menuItems);

    // Filter by category if not 'All'
    if (_selectedCategory.toLowerCase() != 'all') {
      items = items.where((item) => item.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // Filter by search term if provided
    final term = _searchTerm.trim().toLowerCase();
    if (term.isNotEmpty) {
      items = items.where((item) {
        final name = item.name.toLowerCase();
        final desc = item.description.toLowerCase();
        return name.contains(term) || desc.contains(term);
      }).toList();
    }

    return items;
  }

  List<MenuItem> get rawMenuItems => _menuItems;
  String get selectedCategory => _selectedCategory;
  String get searchTerm => _searchTerm;
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
    // clear search when switching category
    _searchTerm = '';
    notifyListeners();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }
}
