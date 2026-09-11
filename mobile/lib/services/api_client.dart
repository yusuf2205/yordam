import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

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
/// The auth token is kept in memory only for this MVP. It should be moved to
/// secure on-device storage (e.g. flutter_secure_storage) before real users'
/// tokens are stored on the device — deferred so this module has no
/// native-plugin dependency until `flutter create` has generated the
/// platform folders.
class ApiClient {
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
    _handleAuthResponse(response);
  }

  Future<void> login({required String phone, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    _handleAuthResponse(response);
  }

  void logout() {
    _accessToken = null;
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

  void _handleAuthResponse(http.Response response) {
    final data = _decode(response) as Map<String, dynamic>;
    _accessToken = data['accessToken'] as String;
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
