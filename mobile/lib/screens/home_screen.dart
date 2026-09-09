import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'ai_chat_screen.dart';
import 'tasks_screen.dart';

/// Main screen, following the mock-up in section 6 of yordam.md: a greeting,
/// a prominent "Чем помочь?" AI input, today's reminders, and a quick-access
/// grid to the other modules.
class HomeScreen extends StatelessWidget {
  final ApiClient apiClient;
  const HomeScreen({super.key, required this.apiClient});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AiChatScreen(apiClient: apiClient)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YORDAM'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${_greeting()} 👋', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Чем помочь?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openChat(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Напишите или скажите...', style: TextStyle(color: Colors.grey)),
                    ),
                    const Icon(Icons.mic_none),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Быстрый доступ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: [
                _QuickAccessTile(
                  icon: Icons.smart_toy_outlined,
                  label: 'AI',
                  onTap: () => _openChat(context),
                ),
                _QuickAccessTile(
                  icon: Icons.check_circle_outline,
                  label: 'Задачи',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TasksScreen(apiClient: apiClient)),
                  ),
                ),
                _QuickAccessTile(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Покупки',
                  onTap: () => _showComingSoon(context, 'Покупки'),
                ),
                _QuickAccessTile(
                  icon: Icons.description_outlined,
                  label: 'Документы',
                  onTap: () => _showComingSoon(context, 'Документы'),
                ),
                _QuickAccessTile(
                  icon: Icons.attach_money,
                  label: 'Деньги',
                  onTap: () => _showComingSoon(context, 'Деньги'),
                ),
                _QuickAccessTile(
                  icon: Icons.home_outlined,
                  label: 'Дом',
                  onTap: () => _showComingSoon(context, 'Дом'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Модуль «$module» появится на следующем этапе')),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}
