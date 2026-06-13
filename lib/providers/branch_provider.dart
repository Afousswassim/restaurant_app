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

  Future<void> selectBranchById(String branchIdOrSlug) async {
    if (branchIdOrSlug.isEmpty) {
      return;
    }

    // First, try to find in cached branches
    Branch? found;
    try {
      found = _branches.firstWhere((b) => b.id == branchIdOrSlug || b.slug == branchIdOrSlug);
    } catch (e) {
      found = null;
    }

    // If not found in cache, load branches from API
    if (found == null) {
      try {
        await loadBranches();
        // Try again after loading
        try {
          found = _branches.firstWhere((b) => b.id == branchIdOrSlug || b.slug == branchIdOrSlug);
        } catch (e) {
          found = null;
        }
      } catch (e) {
        _error = 'Failed to load branches: ${e.toString()}';
      }
    }

    // Set the selected branch if found
    if (found != null) {
      _selectedBranch = found;
      _error = null;
    } else {
      _error = 'Branch not found: $branchIdOrSlug';
      _selectedBranch = null;
    }

    notifyListeners();
  }
}
