import 'package:flutter/material.dart';
import 'loginPage.dart';
import 'notificationService.dart';
import 'medicationLogPage.dart';
import 'app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String? currentUserId;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initialize();
  await NotificationService().requestPermissions();

  NotificationService().onNotificationTap = (medicationId) {
    if (currentUserId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => MedicationLogPage(
            medicationId: medicationId,
            userId: currentUserId!,
          ),
        ),
      );
    } else {}
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Pill Reminder',
      theme: AppTheme.theme,
      home: const LoginPage(),
    );
  }
}
