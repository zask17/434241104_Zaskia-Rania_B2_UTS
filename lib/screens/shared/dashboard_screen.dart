import 'package:flutter/material.dart';
import 'ticket_list_screen.dart';
import '../user/create_ticket_screen.dart';
import 'profile_screen.dart';
import 'ticket_detail_screen.dart';
import 'notification_screen.dart';
import '../../data/session.dart';
import '../../models/user.dart';
import '../../models/ticket.dart';
import '../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Ticket? _selectedTicketForDetail;

  Widget _getSelectedScreen() {
    final user = Session.currentUser;
    final isStaff = user?.role == UserRole.admin || user?.role == UserRole.helpdesk;

    switch (_selectedIndex) {
      case 0:
        return const DashboardHome();
      case 1:
        if (isStaff && _selectedTicketForDetail != null) {
          return TicketDetailScreen(
            ticket: _selectedTicketForDetail!,
            onBack: () => setState(() => _selectedTicketForDetail = null),
          );
        }
        return TicketListScreen(
          onTicketTap: isStaff
              ? (ticket) => setState(() => _selectedTicketForDetail = ticket)
              : null,
        );
      case 2:
        return const ProfileScreen();
      default:
        return const DashboardHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser;
    final isUser = user?.role == UserRole.user;

    return Scaffold(
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _selectedTicketForDetail = null;
          });
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: isUser ? 'Tiket Saya' : 'Semua Tiket',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: (_selectedIndex == 1 && isUser)
          ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
          );
          if (result == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final ApiService _apiService = ApiService();
  late Future<List<Ticket>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _apiService.getTickets();
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser;

    return Scaffold(
      // 🔔 KOREKSI INTEGRASI: Menambahkan tombol lonceng notifikasi ke dalam AppBar
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Ticket>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Ticket> allTickets = snapshot.data ?? [];

          if (user?.role == UserRole.user) {
            allTickets = allTickets.where((t) => t.creatorId == user!.id).toList();
          }

          final totalTickets = allTickets.length;
          final openTickets = allTickets.where((t) => t.status == TicketStatus.open).length;
          final inProgressTickets = allTickets.where((t) => t.status == TicketStatus.inProgress).length;
          final closedTickets = allTickets.where((t) => t.status == TicketStatus.closed).length;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _ticketsFuture = _apiService.getTickets();
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selamat Datang, ${user?.name ?? 'User'}!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Role: ${user?.role.name.toUpperCase()}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: StatCard(title: 'Total Tiket', value: totalTickets.toString(), color: Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(child: StatCard(title: 'Open / Baru', value: openTickets.toString(), color: Colors.cyan)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: StatCard(title: 'In Progress', value: inProgressTickets.toString(), color: Colors.orange)),
                      const SizedBox(width: 16),
                      Expanded(child: StatCard(title: 'Selesai (Closed)', value: closedTickets.toString(), color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Aktivitas Tiket Terbaru', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  allTickets.isEmpty
                      ? const Text('Belum ada aktivitas pelaporan keluhan.', style: TextStyle(color: Colors.grey))
                      : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allTickets.length > 3 ? 3 : allTickets.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final ticket = allTickets[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.history)),
                        title: Text('Tiket "${ticket.title}" terdeteksi'),
                        subtitle: Text('Status: ${ticket.status.name.toUpperCase()} • ID: ${ticket.id}'),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const StatCard({super.key, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}