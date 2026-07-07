import 'package:flutter/material.dart';
import 'ticket_list_screen.dart';
import '../user/create_ticket_screen.dart';
import 'profile_screen.dart';
import 'ticket_detail_screen.dart';
import 'notification_screen.dart';
import '../../data/session.dart';
import '../../data/theme_settings.dart';
import '../../models/user.dart';
import '../../models/ticket.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart' show AppColors;

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

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeSettings.themeMode,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark ||
            (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

        final dynamicNavBg = isDark ? AppColors.bgElevated : Colors.white;
        final dynamicUnselected = isDark ? AppColors.textMuted : const Color(0xFF64748B);

        return Scaffold(
          body: _getSelectedScreen(),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: isDark ? AppColors.border : const Color(0xFFCBD5E1), width: 0.8)),
            ),
            child: BottomNavigationBar(
              backgroundColor: dynamicNavBg,
              currentIndex: _selectedIndex,
              selectedItemColor: AppColors.amber,
              unselectedItemColor: dynamicUnselected,
              elevation: 0,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  _selectedTicketForDetail = null;
                });
              },
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.confirmation_number_rounded),
                  label: isUser ? 'Tiket Saya' : 'Semua Tiket',
                ),
                const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
              ],
            ),
          ),
          floatingActionButton: (_selectedIndex == 1 && isUser)
              ? FloatingActionButton(
            backgroundColor: AppColors.amber,
            foregroundColor: const Color(0xFF121824),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
              );
              if (result == true) {
                setState(() {});
              }
            },
            child: const Icon(Icons.add_rounded, size: 28),
          )
              : null,
        );
      },
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
  bool _hasUnreadNotification = true;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _apiService.getTickets();
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
            title: const Text('Dashboard Overview', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            foregroundColor: dynamicTextPrimary,
            elevation: 0,
            actions: [
              ValueListenableBuilder<bool>(
                valueListenable: ThemeSettings.isLaptopNotificationEnabled,
                builder: (context, isNotificationOn, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: dynamicTextPrimary),
                        onPressed: () {
                          setState(() {
                            _hasUnreadNotification = false;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationScreen()),
                          );
                        },
                      ),
                      if (isNotificationOn && _hasUnreadNotification)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFFE0555C), shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                          ),
                        ),
                    ],
                  );
                },
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
                  color: AppColors.amber,
                  onRefresh: () async {
                    setState(() {
                      _ticketsFuture = _apiService.getTickets();
                    });
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🤖 DIAGNOSTIC CHIP BADGE LOGO - Penambah Visual Estetik Agar Tidak Kosong
                        Row(
                          children: [
                            Container(
                              width: 54, height: 54,
                              decoration: BoxDecoration(
                                color: dynamicSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: dynamicBorder, width: 1.2),
                                boxShadow: [BoxShadow(color: AppColors.amber.withOpacity(0.1), blurRadius: 12)],
                              ),
                              child: const Icon(Icons.app_settings_alt_rounded, size: 28, color: AppColors.amber),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Selamat Datang, ${user?.name ?? 'User'}!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: dynamicTextPrimary)),
                                  const SizedBox(height: 2),
                                  Text('Sistem Operasional Diagnostik • ${user?.role.name.toUpperCase()}', style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 28),

                        // STAT CARDS SKEMA BARU
                        Row(
                          children: [
                            Expanded(child: StatCard(title: 'Total Tiket', value: totalTickets.toString(), color: AppColors.amber, isDark: isDark)),
                            const SizedBox(width: 14),
                            Expanded(child: StatCard(title: 'Open / Baru', value: openTickets.toString(), color: const Color(0xFF38BDF8), isDark: isDark)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: StatCard(title: 'In Progress', value: inProgressTickets.toString(), color: const Color(0xFFFB923C), isDark: isDark)),
                            const SizedBox(width: 14),
                            Expanded(child: StatCard(title: 'Selesai (Closed)', value: closedTickets.toString(), color: const Color(0xFF4ADE80), isDark: isDark)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text('Aktivitas Tiket Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dynamicTextPrimary)),
                        const SizedBox(height: 12),
                        allTickets.isEmpty
                            ? Text('Belum ada aktivitas pelaporan keluhan.', style: TextStyle(color: dynamicTextMuted, fontStyle: FontStyle.italic))
                            : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allTickets.length > 3 ? 3 : allTickets.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final ticket = allTickets[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: dynamicSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: dynamicBorder, width: 0.8),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.amber.withOpacity(0.1),
                                  child: const Icon(Icons.history_toggle_off_rounded, color: AppColors.amber),
                                ),
                                title: Text('Tiket "${ticket.title}"', style: TextStyle(fontWeight: FontWeight.bold, color: dynamicTextPrimary, fontSize: 14)),
                                subtitle: Text('ID: ${ticket.id} • Status: ${ticket.status.name.toUpperCase()}', style: TextStyle(color: dynamicTextMuted, fontSize: 12)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool isDark;

  const StatCard({super.key, required this.title, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.border : const Color(0xFFCBD5E1), width: 1),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, spreadRadius: 1)
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: isDark ? AppColors.textMuted : const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 28)),
        ],
      ),
    );
  }
}