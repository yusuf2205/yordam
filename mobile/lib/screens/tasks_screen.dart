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
    setState(() => _tasksFuture = widget.apiClient.fetchTasks());
    await _tasksFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Задачи')),
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
                  onChanged: null,
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
