import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/task.dart';
import '../models/reminder.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ChatResult {
  final String conversationId;
  final String reply;
  final List<dynamic> toolCalls;

  ChatResult({
    required this.conversationId,
    required this.reply,
    required this.toolCalls,
  });

  factory ChatResult.fromJson(Map<String, dynamic> json) => ChatResult(
        conversationId: json['conversationId'] as String,
        reply: json['reply'] as String,
        toolCalls: (json['toolCalls'] as List<dynamic>?) ?? const [],
      );
}

/// Thin wrapper around the Yordam backend REST API (see backend/src).
///
/// The auth token is cached in memory and mirrored to the platform secure
/// storage (Android Keystore-backed) so the user isn't asked to log in again
/// every time the app is opened — it only expires when the backend's JWT
/// does (30 days, see auth.module.ts) or the user explicitly logs out.
class ApiClient {
  static const _tokenStorageKey = 'yordam_access_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  /// The backend runs on the user's own NAS (see deploy/nas/), reachable
  /// over Tailscale at this MagicDNS hostname on the host port the NAS
  /// docker-compose stack publishes (3005 -> container's 3000). This is
  /// NOT localhost/10.0.2.2 — there is nothing running on the dev machine
  /// itself. A physical device needs Tailscale installed and signed into
  /// the same tailnet to reach this host; swap for a public URL
  /// (e.g. https://api.yordam.uz) once one exists.
  static const String baseUrl = 'http://mynas.tail4bf75c.ts.net:3005/api';

  String? _accessToken;

  bool get isAuthenticated => _accessToken != null;

  Future<void> register({
    required String phone,
    required String password,
    String? name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password, if (name != null) 'name': name}),
    );
    await _handleAuthResponse(response);
  }

  Future<void> login({required String phone, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    await _handleAuthResponse(response);
  }

  /// Restores a previously saved session, if any. Returns whether a token
  /// was found — the caller is responsible for verifying it's still valid
  /// with a real request (e.g. fetchTasks), since the token could have
  /// expired or been revoked server-side since it was saved.
  Future<bool> restoreSession() async {
    // Bounded so a slow/stuck platform keystore never hangs app startup —
    // falls back to the login screen instead.
    final token = await _storage
        .read(key: _tokenStorageKey)
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    if (token == null) return false;
    _accessToken = token;
    return true;
  }

  Future<void> logout() async {
    _accessToken = null;
    await _storage.delete(key: _tokenStorageKey);
  }

  Future<void> resetPassword({required String phone, required String newPassword}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'newPassword': newPassword}),
    );
    _decode(response);
  }

  Future<List<YordamTask>> fetchTasks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: _authHeaders(),
    );
    final data = _decode(response);
    return (data as List<dynamic>)
        .map((item) => YordamTask.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<YordamTask> createTask(String title) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: _authHeaders(),
      body: jsonEncode({'title': title}),
    );
    final data = _decode(response);
    return YordamTask.fromJson(data as Map<String, dynamic>);
  }

  Future<YordamTask> updateTaskStatus(String id, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    final data = _decode(response);
    return YordamTask.fromJson(data as Map<String, dynamic>);
  }

  Future<List<YordamReminder>> fetchReminders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reminders'),
      headers: _authHeaders(),
    );
    final data = _decode(response);
    return (data as List<dynamic>)
        .map((item) => YordamReminder.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<YordamReminder> createReminder(String title, DateTime remindAt) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reminders'),
      headers: _authHeaders(),
      body: jsonEncode({'title': title, 'remindAt': remindAt.toUtc().toIso8601String()}),
    );
    final data = _decode(response);
    return YordamReminder.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteReminder(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/reminders/$id'),
      headers: _authHeaders(),
    );
    _decode(response);
  }

  Future<ChatResult> sendChatMessage(String message, {String? conversationId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: _authHeaders(),
      body: jsonEncode({
        'message': message,
        if (conversationId != null) 'conversationId': conversationId,
      }),
    );
    final data = _decode(response);
    return ChatResult.fromJson(data as Map<String, dynamic>);
  }

  Map<String, String> _authHeaders() => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<void> _handleAuthResponse(http.Response response) async {
    final data = _decode(response) as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String;
    await _storage.write(key: _tokenStorageKey, value: _accessToken);
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Request failed (${response.statusCode})';
    throw ApiException(message);
  }
}
