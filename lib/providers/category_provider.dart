import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  
  List<CategoryModel> get activeCategories => 
      _categories.where((c) => c.status == 'Active').toList();

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories({bool admin = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (admin) {
        _categories = await ApiService.getAdminCategories();
      } else {
        _categories = await ApiService.getPublicCategories();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCategory(CategoryModel category) async {
    final newCat = await ApiService.createAdminCategory(category);
    _categories.insert(0, newCat);
    notifyListeners();
  }

  Future<void> updateCategory(String id, Map<String, dynamic> updates) async {
    final updated = await ApiService.updateAdminCategory(id, updates);
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index] = updated;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String id, String status) async {
    final updated = await ApiService.updateAdminCategoryStatus(id, status);
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id, {String? targetCategoryId}) async {
    await ApiService.deleteAdminCategory(id, targetCategoryId: targetCategoryId);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
