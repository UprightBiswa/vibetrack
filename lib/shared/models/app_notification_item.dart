class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.recipientUserId,
    required this.type,
    required this.title,
    required this.body,
    required this.route,
    required this.entityId,
    required this.payloadJson,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    required this.readAt,
  });

  final String id;
  final String recipientUserId;
  final String type;
  final String title;
  final String body;
  final String route;
  final String entityId;
  final Map<String, dynamic> payloadJson;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? readAt;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id'] as String,
      recipientUserId: (json['recipient_user_id'] ?? '') as String,
      type: (json['type'] ?? 'system') as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      route: (json['route'] ?? '') as String,
      entityId: (json['entity_id'] ?? '') as String,
      payloadJson: (json['payload_json'] ?? const <String, dynamic>{}) as Map<String, dynamic>,
      isRead: (json['is_read'] ?? false) as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      readAt: json['read_at'] == null ? null : DateTime.parse(json['read_at'] as String),
    );
  }
}
