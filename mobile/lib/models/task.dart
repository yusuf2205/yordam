class YordamTask {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final bool createdByAi;

  YordamTask({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdByAi,
  });

  factory YordamTask.fromJson(Map<String, dynamic> json) {
    return YordamTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      priority: json['priority'] as String? ?? 'medium',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      createdByAi: json['createdByAi'] as bool? ?? false,
    );
  }

  bool get isDone => status == 'done';
}
