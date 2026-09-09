import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(YordamApp());
}

class YordamApp extends StatelessWidget {
  final ApiClient apiClient = ApiClient();

  YordamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yordam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
        useMaterial3: true,
      ),
      home: LoginScreen(apiClient: apiClient),
    );
  }
}
