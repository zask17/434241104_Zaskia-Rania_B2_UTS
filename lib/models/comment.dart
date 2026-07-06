class TicketComment {
  final int? id;
  final String ticketId;
  final String commentText;
  final String userName;
  final DateTime createdAt;

  TicketComment({
    this.id,
    required this.ticketId,
    required this.commentText,
    required this.userName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'comment_text': commentText,
      'user_name': userName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      ticketId: json['ticket_id']?.toString() ?? '',
      commentText: json['comment_text'] ?? '',
      userName: json['user_name'] ?? 'Anonymous',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}