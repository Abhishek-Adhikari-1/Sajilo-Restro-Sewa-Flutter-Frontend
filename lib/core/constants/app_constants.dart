import 'dart:io';

class AppConstants {
  static const String appName = 'Sajilo Restro Sewa';
  
  static const String tokenKey = 'session_token';
  static const String themeKey = 'app_theme_mode';

  static const String hostUrl = "http://localhost:5000";
  
  // ── HTTP base URL ─────────────────────────────────────────────────────────
  static String get apiBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api/v1';
    }
    return '$hostUrl/api/v1';
  }

  // ── Socket.IO server URL ──────────────────────────────────────────────────
  static String get socketUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/v1';
    }
    return hostUrl;
  }

  static const String socketPath = '/realtime';
}
