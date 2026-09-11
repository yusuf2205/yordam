import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  final ApiClient apiClient;
  final NotificationService notificationService;
  const RemindersScreen({
    super.key,
    required this.apiClient,
    required this.notificationService,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late Future<List<YordamReminder>> _remindersFuture;

  @override
  void initState() {
    super.initState();
    _remindersFuture = _loadAndSchedule();
  }

  Future<List<YordamReminder>> _loadAndSchedule() async {
    final reminders = await widget.apiClient.fetchReminders();
    // The AI (or another device) may have created reminders since the app
    // last scheduled local notifications for them — reschedule every
    // pending one on each load. scheduleReminder is idempotent (same
    // reminder id -> same notification id), so this just re-confirms
    // already-scheduled ones rather than duplicating them.
    for (final reminder in reminders) {
      if (reminder.isPending) {
        await widget.notificationService.scheduleReminder(
          reminderId: reminder.id,
          title: reminder.title,
          remindAt: reminder.remindAt,
        );
      }
    }
    return reminders;
  }

  Future<void> _refresh() async {
    setState(() {
      _remindersFuture = _loadAndSchedule();
    });
    await _remindersFuture;
  }

  Future<void> _deleteReminder(YordamReminder reminder) async {
    try {
      await widget.apiClient.deleteReminder(reminder.id);
      await widget.notificationService.cancelReminder(reminder.id);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось удалить напоминание: $e')),
        );
      }
    }
  }

  Future<void> _showAddReminderDialog() async {
    final titleController = TextEditingController();
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    String? dialogError;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            String formatDateTime(DateTime dt) {
              String two(int n) => n.toString().padLeft(2, '0');
              return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
            }

            return AlertDialog(
              title: const Text('Новое напоминание'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'О чём напомнить'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date == null || !dialogContext.mounted) return;
                      final time = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time == null) return;
                      setDialogState(() {
                        selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                    child: Text(formatDateTime(selectedDateTime)),
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
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            setDialogState(() => dialogError = 'Введите текст напоминания');
                            return;
                          }
                          if (selectedDateTime.isBefore(DateTime.now())) {
                            setDialogState(() => dialogError = 'Выберите время в будущем');
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });
                          try {
                            final reminder = await widget.apiClient.createReminder(
                              title,
                              selectedDateTime,
                            );
                            await widget.notificationService.scheduleReminder(
                              reminderId: reminder.id,
                              title: reminder.title,
                              remindAt: reminder.remindAt,
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            await _refresh();
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
                      : const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatRemindAt(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Напоминания')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<YordamReminder>>(
          future: _remindersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            }
            final reminders = snapshot.data ?? [];
            if (reminders.isEmpty) {
              return const Center(child: Text('Пока нет напоминаний'));
            }
            return ListView.builder(
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return ListTile(
                  leading: Icon(
                    reminder.isPending ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                  ),
                  title: Text(reminder.title),
                  subtitle: Text(_formatRemindAt(reminder.remindAt)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteReminder(reminder),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
