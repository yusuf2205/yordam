class YordamReminder {
  final String id;
  final String title;
  final DateTime remindAt;
  final String timezone;
  final String status;

  YordamReminder({
    required this.id,
    required this.title,
    required this.remindAt,
    required this.timezone,
    required this.status,
  });

  factory YordamReminder.fromJson(Map<String, dynamic> json) {
    return YordamReminder(
      id: json['id'] as String,
      title: json['title'] as String,
      remindAt: DateTime.parse(json['remindAt'] as String),
      timezone: json['timezone'] as String? ?? 'Asia/Tashkent',
      status: json['status'] as String? ?? 'pending',
    );
  }

  bool get isPending => status == 'pending';
}
