class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String targetYear;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetYear = 'All',
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'General',
      targetYear: json['target_year'] as String? ?? 'All',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? targetYear,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetYear: targetYear ?? this.targetYear,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
