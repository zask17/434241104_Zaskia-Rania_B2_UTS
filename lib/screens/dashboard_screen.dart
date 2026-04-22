import 'package:flutter/material.dart';
import 'ticket_list_screen.dart';
import 'create_ticket_screen.dart';
import 'profile_screen.dart';
import '../data/session.dart';
import '../models/user.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardHome();
      case 1:
        return const TicketListScreen();
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
        onTap: (index) => setState(() => _selectedIndex = index),
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
                  // Memicu rebuild Dashboard untuk merender ulang TicketListScreen dengan data baru
                  setState(() {});
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang, ${user?.name ?? 'User'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Role: ${user?.role.name.toUpperCase()}',
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: StatCard(title: 'Total Tiket', value: '12', color: Colors.blue)),
                SizedBox(width: 16),
                Expanded(child: StatCard(title: 'Aktif', value: '4', color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: StatCard(title: 'Selesai', value: '8', color: Colors.green)),
                SizedBox(width: 16),
                Expanded(child: StatCard(title: 'Dibatalkan', value: '0', color: Colors.red)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Aktivitas Terbaru',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.history)),
                  title: Text('Status Tiket TKT-00${index + 1} diperbarui'),
                  subtitle: const Text('2 jam yang lalu'),
                );
              },
            ),
          ],
        ),
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
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
