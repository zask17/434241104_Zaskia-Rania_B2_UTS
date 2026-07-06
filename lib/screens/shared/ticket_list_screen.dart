import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../data/session.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  final Function(Ticket)? onTicketTap;
  const TicketListScreen({super.key, this.onTicketTap});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Ticket>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _refreshTickets();
  }

  // Fungsi krusial untuk menarik ulang state data terbaru langsung dari cloud API
  void _refreshTickets() {
    setState(() {
      _ticketsFuture = _apiService.getTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.role == UserRole.user ? 'Tiket Saya' : 'Semua Tiket'),
        actions: [
          IconButton(
            onPressed: _refreshTickets,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Ticket>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data tiket di database.'));
          }

          final allTickets = snapshot.data!;

          // Menyaring tiket berdasarkan ID Pembuat jika aktor yang login adalah tipe Regular User
          final tickets = user?.role == UserRole.user
              ? allTickets.where((t) => t.creatorId == user?.id).toList()
              : allTickets;

          if (tickets.isEmpty) {
            return const Center(child: Text('Kamu belum memiliki riwayat keluhan tiket.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshTickets(),
            child: ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () {
                      if (widget.onTicketTap != null) {
                        widget.onTicketTap!(ticket);
                      } else {
                        // Saat kembali dari halaman detail, otomatis refresh list untuk update status terbaru
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TicketDetailScreen(ticket: ticket),
                          ),
                        ).then((_) => _refreshTickets());
                      }
                    },
                    title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${ticket.id}'),
                        Text('Kategori: ${ticket.category}'),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StatusBadge(status: ticket.status),
                        const SizedBox(height: 4),
                        Text(
                          ticket.priority.name.toUpperCase(),
                          style: TextStyle(
                            color: ticket.priority == TicketPriority.high
                                ? Colors.red
                                : ticket.priority == TicketPriority.medium
                                ? Colors.orange
                                : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
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
      case TicketStatus.open: color = Colors.blue; text = 'Open'; break;
      case TicketStatus.inProgress: color = Colors.orange; text = 'In Progress'; break;
      case TicketStatus.resolved: color = Colors.green; text = 'Resolved'; break;
      case TicketStatus.closed: color = Colors.grey; text = 'Closed'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}