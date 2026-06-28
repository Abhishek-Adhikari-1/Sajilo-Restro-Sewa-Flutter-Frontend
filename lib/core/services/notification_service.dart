import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
        
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
        
    const DarwinInitializationSettings initializationSettingsDarwin = 
        DarwinInitializationSettings();

    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
      appName: String.fromEnvironment('RESTRO_NAME', defaultValue: 'Sajilo Restro Sewa'),
      appUserModelId: 'com.example.sajilo_restro_sewa',
      guid: '8cbe9d8d-933e-48a0-819a-251f7bb8cf6d',
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            linux: initializationSettingsLinux,
            iOS: initializationSettingsDarwin,
            macOS: initializationSettingsDarwin,
            windows: initializationSettingsWindows,
        );
        
    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  static Future<void> triggerNewOrderAlert(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final bool isNotificationEnabled = prefs.getBool('enable_notifications') ?? false;
    final bool isSoundEnabled = prefs.getBool('enable_sound') ?? true;
    final bool isVibrationEnabled = prefs.getBool('enable_vibration') ?? true;

    // Vibration
    if (isVibrationEnabled) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [500, 1000, 500, 1000]);
      }
    }

    // Sound
    if (isSoundEnabled) {
      FlutterRingtonePlayer().playNotification();
    }

    // Notification
    if (isNotificationEnabled) {
      var status = await Permission.notification.status;
      if (status.isGranted) {
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'new_order_channel',
          'New Orders',
          channelDescription: 'Notifications for new orders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: false, // We handle sound explicitly via ringtone player if needed
          enableVibration: false, // We handle vibration explicitly
        );
        const LinuxNotificationDetails linuxPlatformChannelSpecifics = 
            LinuxNotificationDetails();
            
        const DarwinNotificationDetails darwinPlatformChannelSpecifics =
            DarwinNotificationDetails(presentSound: false);

        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(
                android: androidPlatformChannelSpecifics,
                linux: linuxPlatformChannelSpecifics,
                iOS: darwinPlatformChannelSpecifics,
                macOS: darwinPlatformChannelSpecifics,
            );
            
        await _notificationsPlugin.show(
          id: orderId.hashCode,
          title: 'New Order Received!',
          body: 'Order #${orderId.substring(0, 6).toUpperCase()} has just been placed.',
          notificationDetails: platformChannelSpecifics,
        );
      }
    }
  }

  static Future<void> triggerOrderUpdatedAlert(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final bool isNotificationEnabled = prefs.getBool('enable_notifications') ?? false;
    final bool isSoundEnabled = prefs.getBool('enable_sound') ?? true;
    final bool isVibrationEnabled = prefs.getBool('enable_vibration') ?? true;

    if (isVibrationEnabled) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [200, 300, 200, 300]);
      }
    }

    if (isSoundEnabled) {
      FlutterRingtonePlayer().playNotification();
    }

    if (isNotificationEnabled) {
      var status = await Permission.notification.status;
      if (status.isGranted) {
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'order_update_channel',
          'Order Updates',
          channelDescription: 'Notifications for updated orders',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: false,
        );
        const LinuxNotificationDetails linuxPlatformChannelSpecifics = 
            LinuxNotificationDetails();
            
        const DarwinNotificationDetails darwinPlatformChannelSpecifics =
            DarwinNotificationDetails(presentSound: false);

        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(
                android: androidPlatformChannelSpecifics,
                linux: linuxPlatformChannelSpecifics,
                iOS: darwinPlatformChannelSpecifics,
                macOS: darwinPlatformChannelSpecifics,
            );
            
        await _notificationsPlugin.show(
          id: orderId.hashCode + 1, // Offset ID so it doesn't overwrite new order if both exist
          title: 'Order Updated!',
          body: 'Order #${orderId.substring(0, 6).toUpperCase()} has new items or notes.',
          notificationDetails: platformChannelSpecifics,
        );
      }
    }
  }
}
