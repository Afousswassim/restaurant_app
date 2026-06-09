import 'package:flutter/material.dart';
import '../models/branch.dart';
import '../services/api_service.dart';

class BranchProvider with ChangeNotifier {
  List<Branch> _branches = [];
  Branch? _selectedBranch;
  bool _isLoading = false;
  String? _error;

  List<Branch> get branches => _branches;
  Branch? get selectedBranch => _selectedBranch;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBranches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _branches = await ApiService.getBranches();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _branches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectBranch(Branch branch) {
    _selectedBranch = branch;
    notifyListeners();
  }
}
