import 'package:flutter/material.dart';
import 'core/services/notification_service.dart';
import 'core/services/deep_link_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await DeepLinkService.instance.init();
  runApp(const App());
}
