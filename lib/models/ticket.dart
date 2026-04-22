enum TicketStatus { open, inProgress, resolved, closed }
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
  });

  Ticket copyWith({
    TicketStatus? status,
    List<TicketHistory>? history,
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
}
