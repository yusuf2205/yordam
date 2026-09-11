import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final ApiClient apiClient;
  final NotificationService notificationService;
  const LoginScreen({super.key, required this.apiClient, required this.notificationService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_isRegisterMode) {
        await widget.apiClient.register(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        );
      } else {
        await widget.apiClient.login(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            apiClient: widget.apiClient,
            notificationService: widget.notificationService,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final phoneController = TextEditingController(text: _phoneController.text.trim());
    final newPasswordController = TextEditingController();
    String? dialogError;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Восстановление пароля'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Телефон', hintText: '+998901234567'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Новый пароль'),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(dialogError!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });
                          try {
                            await widget.apiClient.resetPassword(
                              phone: phoneController.text.trim(),
                              newPassword: newPasswordController.text,
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            if (!mounted) return;
                            _phoneController.text = phoneController.text.trim();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Пароль обновлён. Войдите с новым паролем.')),
                            );
                          } catch (e) {
                            setDialogState(() {
                              dialogError = e.toString();
                              isSubmitting = false;
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'YORDAM',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Скажи, что нужно. Yordam поможет сделать.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  if (_isRegisterMode) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Имя'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Телефон', hintText: '+998901234567'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Пароль'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isRegisterMode ? 'Зарегистрироваться' : 'Войти'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
                    child: Text(_isRegisterMode
                        ? 'Уже есть аккаунт? Войти'
                        : 'Нет аккаунта? Зарегистрироваться'),
                  ),
                  if (!_isRegisterMode)
                    TextButton(
                      onPressed: _isLoading ? null : _showResetPasswordDialog,
                      child: const Text('Забыли пароль?'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
