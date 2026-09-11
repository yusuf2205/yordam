import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_client.dart';

class TasksScreen extends StatefulWidget {
  final ApiClient apiClient;
  const TasksScreen({super.key, required this.apiClient});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late Future<List<YordamTask>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = widget.apiClient.fetchTasks();
  }

  Future<void> _refresh() async {
    setState(() {
      _tasksFuture = widget.apiClient.fetchTasks();
    });
    await _tasksFuture;
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    String? dialogError;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Новая задача'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Название'),
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
                            setDialogState(() => dialogError = 'Введите название задачи');
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });
                          try {
                            await widget.apiClient.createTask(title);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Задачи')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<YordamTask>>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            }
            final tasks = snapshot.data ?? [];
            if (tasks.isEmpty) {
              return const Center(child: Text('Пока нет задач'));
            }
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return CheckboxListTile(
                  value: task.isDone,
                  onChanged: (checked) async {
                    final newStatus = checked == true ? 'done' : 'pending';
                    try {
                      await widget.apiClient.updateTaskStatus(task.id, newStatus);
                      await _refresh();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Не удалось обновить задачу: $e')),
                        );
                      }
                    }
                  },
                  title: Text(task.title),
                  subtitle: task.description != null ? Text(task.description!) : null,
                  secondary: task.createdByAi ? const Icon(Icons.auto_awesome) : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
