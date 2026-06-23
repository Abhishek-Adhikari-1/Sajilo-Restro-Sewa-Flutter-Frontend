import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UserAgentService {
  static String? _cachedUserAgent;

  /// Build and cache a descriptive User-Agent string.
  /// Example: "SajiloRestroSewa/1.0.0 (Android 13; samsung SM-G991B)"
  static Future<String> getUserAgent() async {
    if (_cachedUserAgent != null) return _cachedUserAgent!;

    final deviceInfo = DeviceInfoPlugin();
    PackageInfo packageInfo;

    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (_) {
      packageInfo = PackageInfo(
        appName: 'SajiloRestroSewa',
        packageName: 'com.example.sajilo_restro_sewa',
        version: '1.0.0',
        buildNumber: '1',
      );
    }

    final appName = packageInfo.appName.replaceAll(' ', '');
    final version = packageInfo.version;

    String devicePart = 'Unknown';

    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        final brand = info.brand.isEmpty ? 'Android' : _capitalize(info.brand);
        final model = info.model;
        final sdkInt = info.version.sdkInt;
        // Convert SDK int to rough Android version
        final androidVersion = _sdkToAndroidVersion(sdkInt);
        devicePart = 'Android $androidVersion; $brand $model';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        final systemVersion = info.systemVersion;
        final model = info.utsname.machine; // e.g. iPhone14,2
        devicePart = 'iOS $systemVersion; $model';
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        devicePart = 'Linux; ${info.prettyName}';
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        devicePart =
            'Windows ${info.majorVersion}.${info.minorVersion}; ${info.computerName}';
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        devicePart = 'macOS ${info.osRelease}; ${info.model}';
      }
    } catch (_) {
      // Fallback to platform string
      devicePart = Platform.operatingSystem;
    }

    _cachedUserAgent = '$appName/$version ($devicePart)';
    return _cachedUserAgent!;
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String _sdkToAndroidVersion(int sdk) {
    const map = {
      21: '5.0', 22: '5.1', 23: '6.0', 24: '7.0', 25: '7.1',
      26: '8.0', 27: '8.1', 28: '9',   29: '10',  30: '11',
      31: '12',  32: '12L', 33: '13',  34: '14',  35: '15',
    };
    return map[sdk] ?? '$sdk';
  }
}
