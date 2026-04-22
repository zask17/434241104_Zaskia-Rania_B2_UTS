import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../data/session.dart';
import '../data/dummy_data.dart';

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late Ticket _currentTicket;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
  }

  void _updateStatus(TicketStatus newStatus) {
    // 1. Buat riwayat baru
    final newHistoryItem = TicketHistory(
      message: 'Status diubah menjadi ${newStatus.name.toUpperCase()}',
      timestamp: DateTime.now(),
      userName: Session.currentUser?.name ?? 'Staff',
    );

    // 2. Buat objek tiket baru dengan status dan riwayat terupdate
    final updatedTicket = _currentTicket.copyWith(
      status: newStatus,
      history: [newHistoryItem, ..._currentTicket.history],
    );

    // 3. Update di list global DummyData agar perubahan terlihat di halaman lain
    final index = DummyData.tickets.indexWhere((t) => t.id == _currentTicket.id);
    if (index != -1) {
      DummyData.tickets[index] = updatedTicket;
    }

    // 4. Update UI lokal
    setState(() {
      _currentTicket = updatedTicket;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status ${_currentTicket.id} berhasil diubah')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser;
    final isStaff = user?.role == UserRole.admin || user?.role == UserRole.helpdesk;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTicket.id),
        actions: isStaff
            ? [
                PopupMenuButton<TicketStatus>(
                  onSelected: _updateStatus,
                  itemBuilder: (context) => TicketStatus.values.map((status) {
                    return PopupMenuItem<TicketStatus>(
                      value: status,
                      child: Text('Set ke ${status.name.toUpperCase()}'),
                    );
                  }).toList(),
                  icon: const Icon(Icons.edit_calendar),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentTicket.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusBadge(status: _currentTicket.status),
                const SizedBox(width: 8),
                Text(_currentTicket.category, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Divider(height: 32),
            Text('Deskripsi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_currentTicket.description),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('Tracking / Riwayat', 
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (isStaff)
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur Assign Tiket')),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Assign'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentTicket.history.length,
              itemBuilder: (context, index) {
                final history = _currentTicket.history[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                          if (index != _currentTicket.history.length - 1)
                            Container(width: 2, height: 40, color: Colors.blue.withOpacity(0.3)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(history.message, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${history.userName} • ${history.timestamp.toString().substring(0, 16)}', 
                                 style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Tambahkan komentar...',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.send),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
