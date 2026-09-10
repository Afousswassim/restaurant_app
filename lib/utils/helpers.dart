import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SessionManager {
  static const String _sessionIdKey = 'app_session_id';
  static late String _sessionId;
  static bool _initialized = false;

  static String get sessionId => _sessionId;

  static Future<void> ensureSession() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_sessionIdKey);

    if (saved != null && saved.isNotEmpty) {
      _sessionId = saved;
    } else {
      _sessionId = const Uuid().v4();
      await prefs.setString(_sessionIdKey, _sessionId);
    }

    _initialized = true;
  }

  static Future<void> resetSession() async {
    _sessionId = const Uuid().v4();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, _sessionId);
  }
}

class CurrencyFormatter {
  static String formatDH(double amount) {
    return '${amount.toStringAsFixed(0)} DH';
  }

  static double parseDH(String text) {
    return double.tryParse(text.replaceAll(' DH', '')) ?? 0;
  }
}

class ResponsiveUtil {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  static bool isMobile(double width) => width < mobileBreakpoint;
  static bool isTablet(double width) =>
      width >= mobileBreakpoint && width < desktopBreakpoint;
  static bool isDesktop(double width) => width >= desktopBreakpoint;
  static bool isSmallScreen(double width) => width < tabletBreakpoint;
}

class ValidationUtil {
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10,15}$').hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''));
  }

  static bool isValidAddress(String address) {
    return address.trim().length >= 5;
  }
}

class OrderStatusUtil {
  static Color getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'pending':
        return const Color(0xFFF59E0B); // Orange / Amber
      case 'preparing':
        return const Color(0xFF3B82F6); // Blue
      case 'delivering':
      case 'on-way':
      case 'ready':
        return const Color(0xFF8B5CF6); // Purple
      case 'delivered':
        return const Color(0xFF10B981); // Green
      case 'cancelled':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B);
    }
  }

  static Color getStatusBgColor(String status, bool isDark) {
    final baseColor = getStatusColor(status);
    if (isDark) {
      return baseColor.withValues(alpha: 0.18);
    } else {
      switch (status.toLowerCase().trim()) {
        case 'pending':
          return const Color(0xFFFEF3C7);
        case 'preparing':
          return const Color(0xFFE0F2FE);
        case 'delivering':
        case 'on-way':
        case 'ready':
          return const Color(0xFFF3E8FF);
        case 'delivered':
          return const Color(0xFFDCFCE7);
        case 'cancelled':
          return const Color(0xFFFEE2E2);
        default:
          return const Color(0xFFF1F5F9);
      }
    }
  }

  static String getStatusDisplay(String status) {
    switch (status.toLowerCase().trim()) {
      case 'pending':
        return 'Pending';
      case 'preparing':
        return 'Preparing';
      case 'delivering':
        return 'Delivering';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : 'Unknown';
    }
  }
}
