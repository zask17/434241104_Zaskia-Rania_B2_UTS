import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../data/dummy_data.dart';
import '../data/session.dart';
import '../models/user.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser;
    final tickets = user?.role == UserRole.user
        ? DummyData.tickets.where((t) => t.creatorId == user?.id).toList()
        : DummyData.tickets;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.role == UserRole.user ? 'Tiket Saya' : 'Semua Tiket'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
        ],
      ),
      body: ListView.builder(
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TicketDetailScreen(ticket: ticket)),
                ).then((_) {
                  // Rebuild halaman saat kembali dari detail untuk melihat update status
                  setState(() {});
                });
              },
              title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.id),
                  Text(ticket.category),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status: ticket.status),
                  const SizedBox(height: 4),
                  Text(
                    _getPriorityText(ticket.priority),
                    style: TextStyle(color: _getPriorityColor(ticket.priority), fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getPriorityText(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low: return 'Low';
      case TicketPriority.medium: return 'Medium';
      case TicketPriority.high: return 'High';
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low: return Colors.green;
      case TicketPriority.medium: return Colors.orange;
      case TicketPriority.high: return Colors.red;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final TicketStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case TicketStatus.open:
        color = Colors.blue;
        text = 'Open';
        break;
      case TicketStatus.inProgress:
        color = Colors.orange;
        text = 'In Progress';
        break;
      case TicketStatus.resolved:
        color = Colors.green;
        text = 'Resolved';
        break;
      case TicketStatus.closed:
        color = Colors.grey;
        text = 'Closed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }
}
