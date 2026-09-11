class YordamCalendarEvent {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startAt;
  final DateTime? endAt;
  final int? reminderMinutes;
  final String status;

  YordamCalendarEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startAt,
    this.endAt,
    this.reminderMinutes,
    required this.status,
  });

  factory YordamCalendarEvent.fromJson(Map<String, dynamic> json) {
    return YordamCalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: json['endAt'] != null ? DateTime.tryParse(json['endAt'] as String) : null,
      reminderMinutes: json['reminderMinutes'] as int?,
      status: json['status'] as String? ?? 'confirmed',
    );
  }

  bool get isCancelled => status == 'cancelled';
}
