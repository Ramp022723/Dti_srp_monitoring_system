class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final String priority;
  final String status;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? senderId;
  final String? senderName;
  final String? recipientId;
  final String? recipientName;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.status,
    this.actionUrl,
    this.metadata,
    required this.createdAt,
    this.readAt,
    this.senderId,
    this.senderName,
    this.recipientId,
    this.recipientName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? json['notification_id'] ?? 0,
      title: json['title'] ?? json['subject'] ?? 'Notification',
      message: json['message'] ?? json['content'] ?? json['description'] ?? '',
      type: json['type'] ?? json['notification_type'] ?? 'info',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? json['read_status'] ?? 'unread',
      actionUrl: json['action_url'] ?? json['link'],
      metadata: json['metadata'] ?? json['data'],
      createdAt: DateTime.tryParse(json['created_at'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      senderId: json['sender_id'],
      senderName: json['sender_name'] ?? json['sender'],
      recipientId: json['recipient_id'] ?? json['user_id'],
      recipientName: json['recipient_name'] ?? json['recipient'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'status': status,
      'action_url': actionUrl,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'sender_id': senderId,
      'sender_name': senderName,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
    };
  }

  bool get isRead => status == 'read' || readAt != null;
  bool get isUnread => !isRead;
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return '#EF4444'; // Red
      case 'medium':
        return '#F59E0B'; // Amber
      case 'low':
        return '#10B981'; // Green
      default:
        return '#6B7280'; // Gray
    }
  }

  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'alert':
      case 'warning':
        return '⚠️';
      case 'info':
      case 'information':
        return 'ℹ️';
      case 'success':
        return '✅';
      case 'error':
        return '❌';
      case 'price_freeze':
        return '🧊';
      case 'complaint':
        return '📝';
      case 'system':
        return '⚙️';
      default:
        return '🔔';
    }
  }
}

class NotificationStats {
  final int total;
  final int unread;
  final int read;
  final int highPriority;
  final int mediumPriority;
  final int lowPriority;
  final Map<String, int> typeCounts;

  NotificationStats({
    required this.total,
    required this.unread,
    required this.read,
    required this.highPriority,
    required this.mediumPriority,
    required this.lowPriority,
    required this.typeCounts,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      total: json['total'] ?? 0,
      unread: json['unread'] ?? 0,
      read: json['read'] ?? 0,
      highPriority: json['high_priority'] ?? 0,
      mediumPriority: json['medium_priority'] ?? 0,
      lowPriority: json['low_priority'] ?? 0,
      typeCounts: Map<String, int>.from(json['type_counts'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'unread': unread,
      'read': read,
      'high_priority': highPriority,
      'medium_priority': mediumPriority,
      'low_priority': lowPriority,
      'type_counts': typeCounts,
    };
  }
}
