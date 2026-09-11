import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../services/api_client.dart';

class CalendarScreen extends StatefulWidget {
  final ApiClient apiClient;
  const CalendarScreen({super.key, required this.apiClient});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<List<YordamCalendarEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = widget.apiClient.fetchCalendarEvents();
  }

  Future<void> _refresh() async {
    setState(() {
      _eventsFuture = widget.apiClient.fetchCalendarEvents();
    });
    await _eventsFuture;
  }

  Future<void> _deleteEvent(YordamCalendarEvent event) async {
    try {
      await widget.apiClient.deleteCalendarEvent(event.id);
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось удалить событие: $e')),
        );
      }
    }
  }

  Future<void> _showAddEventDialog() async {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final reminderMinutesController = TextEditingController();
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
              title: const Text('Новое событие'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Название'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Место (необязательно)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reminderMinutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Напомнить за (минут, необязательно)',
                      ),
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
                            setDialogState(() => dialogError = 'Введите название события');
                            return;
                          }
                          if (selectedDateTime.isBefore(DateTime.now())) {
                            setDialogState(() => dialogError = 'Выберите время в будущем');
                            return;
                          }
                          final reminderText = reminderMinutesController.text.trim();
                          final reminderMinutes = reminderText.isEmpty ? null : int.tryParse(reminderText);
                          if (reminderText.isNotEmpty && reminderMinutes == null) {
                            setDialogState(() => dialogError = 'Введите число минут');
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });
                          try {
                            await widget.apiClient.createCalendarEvent(
                              title: title,
                              startAt: selectedDateTime,
                              location: locationController.text.trim(),
                              reminderMinutes: reminderMinutes,
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

  String _formatEventTime(YordamCalendarEvent event) {
    final start = event.startAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${two(start.day)}.${two(start.month)}.${start.year}';
    final time = '${two(start.hour)}:${two(start.minute)}';
    final parts = <String>['$date $time'];
    if (event.location != null && event.location!.isNotEmpty) {
      parts.add(event.location!);
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Календарь')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<YordamCalendarEvent>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            }
            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return const Center(child: Text('Пока нет событий'));
            }
            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  leading: Icon(
                    event.isCancelled ? Icons.event_busy_outlined : Icons.event_outlined,
                  ),
                  title: Text(
                    event.title,
                    style: event.isCancelled
                        ? const TextStyle(decoration: TextDecoration.lineThrough)
                        : null,
                  ),
                  subtitle: Text(_formatEventTime(event)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteEvent(event),
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
