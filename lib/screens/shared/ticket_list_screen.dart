import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../data/session.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../data/theme_settings.dart';
import '../../theme/app_theme.dart' show AppColors;
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

  void _refreshTickets() {
    setState(() {
      _ticketsFuture = _apiService.getTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeSettings.themeMode,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark ||
            (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

        final dynamicBgDeep = isDark ? AppColors.bgDeep : const Color(0xFFF4F6F9);
        final dynamicBgElevated = isDark ? AppColors.bgElevated : const Color(0xFFE2E8F0);
        final dynamicSurface = isDark ? AppColors.surface : Colors.white;
        final dynamicBorder = isDark ? AppColors.border : const Color(0xFFCBD5E1);
        final dynamicTextPrimary = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
        final dynamicTextMuted = isDark ? AppColors.textMuted : const Color(0xFF64748B);

        return Scaffold(
          appBar: AppBar(
            title: Text(user?.role == UserRole.user ? 'Tiket Saya' : 'Semua Tiket', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            foregroundColor: dynamicTextPrimary,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: _refreshTickets,
                icon: Icon(Icons.refresh_rounded, color: dynamicTextPrimary),
              ),
            ],
          ),
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [dynamicBgDeep, dynamicBgElevated],
              ),
            ),
            child: FutureBuilder<List<Ticket>>(
              future: _ticketsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.amber));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: dynamicTextPrimary)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Tidak ada data tiket.', style: TextStyle(color: dynamicTextMuted)));
                }

                final allTickets = snapshot.data!;
                final tickets = user?.role == UserRole.user
                    ? allTickets.where((t) => t.creatorId == user?.id).toList()
                    : allTickets;

                if (tickets.isEmpty) {
                  return Center(child: Text('Kamu belum memiliki riwayat keluhan tiket.', style: TextStyle(color: dynamicTextMuted)));
                }

                return RefreshIndicator(
                  color: AppColors.amber,
                  onRefresh: () async => _refreshTickets(),
                  child: ListView.builder(
                    itemCount: tickets.length,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: dynamicSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: dynamicBorder, width: 0.8),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (widget.onTicketTap != null) {
                              widget.onTicketTap!(ticket);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TicketDetailScreen(ticket: ticket),
                                ),
                              ).then((_) => _refreshTickets());
                            }
                          },
                          title: Text(ticket.title, style: TextStyle(fontWeight: FontWeight.bold, color: dynamicTextPrimary)),
                          subtitle: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${ticket.id}', style: TextStyle(color: dynamicTextMuted, fontSize: 12)),
                                Text('Kategori: ${ticket.category}', style: TextStyle(color: dynamicTextMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center, // Memastikan konten berada di tengah vertikal
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min, // SANGAT PENTING: Mencegah Column mengambil tinggi tak terbatas
                            children: [
                              _StatusBadge(status: ticket.status),
                              const SizedBox(height: 4), // Kurangi jarak spacing dari 8 menjadi 4 agar lebih hemat ruang
                              Text(
                                ticket.priority.name.toUpperCase(),
                                style: TextStyle(
                                  color: ticket.priority == TicketPriority.high
                                      ? const Color(0xFFE0555C)
                                      : ticket.priority == TicketPriority.medium
                                      ? const Color(0xFFFB923C)
                                      : const Color(0xFF4ADE80),
                                  fontSize: 10, // Perkecil sedikit ukuran font dari 11 menjadi 10
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
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
          ),
        );
      },
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
      case TicketStatus.open: color = const Color(0xFF38BDF8); text = 'Open'; break;
      case TicketStatus.inProgress: color = const Color(0xFFFB923C); text = 'In Progress'; break;
      case TicketStatus.closed: color = const Color(0xFF94A3B8); text = 'Closed'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color, width: 0.8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}