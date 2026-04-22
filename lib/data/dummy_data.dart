import '../models/ticket.dart';
import '../models/user.dart';

class DummyData {
  static final List<User> users = [
    User(id: '1', name: 'Admin Ticketing', email: 'admin@mail.com', password: 'admin123', role: UserRole.admin),
    User(id: '2', name: 'Helpdesk Staff', email: 'helpdesk@mail.com', password: 'helpdesk123', role: UserRole.helpdesk),
    User(id: '3', name: 'Regular User', email: 'user@mail.com', password: 'user123', role: UserRole.user),
  ];

  static final List<Ticket> tickets = [
    Ticket(
      id: 'TKT-001',
      title: 'Laptop tidak bisa menyala',
      description: 'Laptop saya tiba-tiba mati dan tidak bisa dinyalakan kembali meskipun sudah dicharge.',
      status: TicketStatus.open,
      priority: TicketPriority.high,
      category: 'Hardware',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      creatorId: '3',
      creatorName: 'Regular User',
      history: [
        TicketHistory(
          message: 'Tiket dibuat',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          userName: 'Regular User',
        ),
      ],
    ),
    Ticket(
      id: 'TKT-002',
      title: 'Akses VPN bermasalah',
      description: 'Saya tidak bisa login ke VPN kantor sejak pagi tadi.',
      status: TicketStatus.inProgress,
      priority: TicketPriority.medium,
      category: 'Network',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      creatorId: '3',
      creatorName: 'Regular User',
      history: [
        TicketHistory(
          message: 'Tiket dibuat',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          userName: 'Regular User',
        ),
        TicketHistory(
          message: 'Sedang dicek oleh tim IT',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          userName: 'Helpdesk Staff',
        ),
      ],
    ),
    Ticket(
      id: 'TKT-003',
      title: 'Lupa password email',
      description: 'Mohon bantuan untuk reset password email korporat.',
      status: TicketStatus.resolved,
      priority: TicketPriority.low,
      category: 'Account',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      creatorId: '3',
      creatorName: 'Regular User',
      history: [
        TicketHistory(
          message: 'Tiket dibuat',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          userName: 'Regular User',
        ),
        TicketHistory(
          message: 'Password telah direset',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          userName: 'Helpdesk Staff',
        ),
      ],
    ),
  ];
}
