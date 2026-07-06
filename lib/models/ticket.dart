enum TicketStatus { open, inProgress, closed }
enum TicketPriority { low, medium, high }

class Ticket {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final String category;
  final DateTime createdAt;
  final String creatorId;
  final String creatorName;
  final List<String> attachments;
  final List<TicketHistory> history;
  final String? helpdeskId;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.createdAt,
    required this.creatorId,
    required this.creatorName,
    this.attachments = const [],
    this.history = const [],
    this.helpdeskId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'creator_id': creatorId,
      'creator_name': creatorName,
      'attachments': attachments,
      'helpdesk_id': helpdeskId,
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: TicketStatus.values.firstWhere(
            (e) => e.name == json['status'],
        orElse: () => TicketStatus.open,
      ),
      priority: TicketPriority.values.firstWhere(
            (e) => e.name == json['priority'],
        orElse: () => TicketPriority.low,
      ),
      category: json['category'] ?? 'General',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      creatorId: json['creator_id']?.toString() ?? '',
      creatorName: json['creator_name'] ?? '',
      attachments: List<String>.from(json['attachments'] ?? []),
      helpdeskId: json['helpdesk_id']?.toString(),
      history: (json['ticket_histories'] as List? ?? [])
          .map((e) => TicketHistory.fromJson(e))
          .toList(),
    );
  }

  Ticket copyWith({
    TicketStatus? status,
    List<TicketHistory>? history,
    String? helpdeskId,
  }) {
    return Ticket(
      id: id,
      title: title,
      description: description,
      status: status ?? this.status,
      priority: priority,
      category: category,
      createdAt: createdAt,
      creatorId: creatorId,
      creatorName: creatorName,
      attachments: attachments,
      helpdeskId: helpdeskId ?? this.helpdeskId,
      history: history ?? this.history,
    );
  }
}

class TicketHistory {
  final String message;
  final DateTime timestamp;
  final String userName;

  TicketHistory({
    required this.message,
    required this.timestamp,
    required this.userName,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user_name': userName,
      'created_at': timestamp.toIso8601String(),
    };
  }

  factory TicketHistory.fromJson(Map<String, dynamic> json) {
    return TicketHistory(
      message: json['message'] ?? '',
      userName: json['user_name'] ?? 'System',
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}