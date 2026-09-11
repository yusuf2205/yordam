import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'screens/startup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.init();
  runApp(YordamApp(notificationService: notificationService));
}

class YordamApp extends StatelessWidget {
  final ApiClient apiClient = ApiClient();
  final NotificationService notificationService;

  YordamApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yordam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
        useMaterial3: true,
      ),
      home: StartupScreen(apiClient: apiClient, notificationService: notificationService),
    );
  }
}
