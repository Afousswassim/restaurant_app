import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((notification) => !notification.isRead).length;

  Future<void> loadNotifications(String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getNotifications(clientId);
      _notifications = data;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiService.markNotificationAsRead(id);
      final index = _notifications.indexWhere((item) => item.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead(String clientId) async {
    try {
      await ApiService.markAllNotificationsAsRead(clientId);
      _notifications = _notifications.map((item) => item.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (_) {}
  }
}
