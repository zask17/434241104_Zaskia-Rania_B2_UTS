import 'package:flutter/material.dart';
import '../../data/session.dart';
import '../../services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>?> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _refreshNotifications();
  }

  void _refreshNotifications() {
    final user = Session.currentUser;
    // Deteksi role_id internal: admin = 1, helpdesk = 2, user = 3
    int roleId = user?.role.index == 0 ? 1 : (user?.role.index == 1 ? 2 : 3);

    setState(() {
      _notificationsFuture = _apiService.fetchLiveNotifications(
        roleId: roleId,
        userId: user?.id ?? '',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi Servis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNotifications,
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>?>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Gagal memuat data dari server.'));
          }

          final liveNotifications = snapshot.data!;

          if (liveNotifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada notifikasi baru.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshNotifications(),
            child: ListView.separated(
              itemCount: liveNotifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = liveNotifications[index];

                // Formatting format jam mentah Supabase sederhana
                String rawTime = item['created_at'] ?? '';
                String formattedTime = rawTime.length > 16
                    ? rawTime.substring(0, 16).replaceAll('T', ' ')
                    : 'Baru saja';

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.build, color: Colors.white, size: 18),
                  ),
                  title: Text(
                    item['title'] ?? 'Update Tiket',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(item['description'] ?? '', style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(formattedTime, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            ),
          );
        },
      ),
    );
  }
}