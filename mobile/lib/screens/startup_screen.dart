import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Shown briefly at app launch while we check for a saved session, so the
/// user isn't sent back to the login screen every time they open the app —
/// only once the saved token actually stops working (expiry or logout).
class StartupScreen extends StatefulWidget {
  final ApiClient apiClient;
  final NotificationService notificationService;
  const StartupScreen({
    super.key,
    required this.apiClient,
    required this.notificationService,
  });

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _resolveStartRoute();
  }

  Future<void> _resolveStartRoute() async {
    var loggedIn = false;
    try {
      if (await widget.apiClient.restoreSession()) {
        // A saved token doesn't mean it's still valid (expired, or revoked
        // by a password reset) — confirm with a real request before
        // trusting it.
        try {
          await widget.apiClient.fetchTasks();
          loggedIn = true;
        } catch (_) {
          await widget.apiClient.logout();
        }
      }
    } catch (_) {
      // No secure storage available (e.g. a widget test host with no
      // platform channels) or the read itself failed — treat as logged out.
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => loggedIn
            ? HomeScreen(
                apiClient: widget.apiClient,
                notificationService: widget.notificationService,
              )
            : LoginScreen(
                apiClient: widget.apiClient,
                notificationService: widget.notificationService,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
