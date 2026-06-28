import 'package:flutter/material.dart';
import '../models/ai_recommendation.dart';
import '../services/api_service.dart';

class AiProvider with ChangeNotifier {
  AiRecommendation? _recommendation;
  bool _isLoading = false;
  String? _error;

  AiRecommendation? get recommendation => _recommendation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> generatePlan({
    required String mode,
    String? clientId,
    String? branchId,
    String? goal,
    double? budget,
    int? people,
    String? preference,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recommendation = await ApiService.generateAiFoodPlan(
        mode: mode,
        clientId: clientId,
        branchId: branchId,
        goal: goal,
        budget: budget,
        people: people,
        preference: preference,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _recommendation = null;
    _error = null;
    notifyListeners();
  }
}
