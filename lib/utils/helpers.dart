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
