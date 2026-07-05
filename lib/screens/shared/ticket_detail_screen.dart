// import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../data/session.dart';
import '../../services/api_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  final VoidCallback? onBack;
  const TicketDetailScreen({super.key, required this.ticket, this.onBack});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late Ticket _currentTicket;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<dynamic> _ticketHistoryList = [];

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    _fetchTicketHistory(); // Ambil riwayat perjalanan tiket dari database API
  }

  // Mengambil data riwayat perjalanan tiket terbaru langsung dari API Supabase
  Future<void> _fetchTicketHistory() async {
    try {
      final response = await _apiService.getTicketHistory(_currentTicket.id);
      if (response != null) {
        setState(() {
          _ticketHistoryList = response;
        });
      }
    } catch (e) {
      print('Error fetching history from API: $e');
    }
  }

  // ALUR 2 & 3: Proses Assign Helpdesk oleh Admin via API (Status otomatis berubah ke In Progress)
  void _handleAssignHelpdesk() async {
    // Simulasi ID helpdesk yang ditugaskan (bisa diintegrasikan dengan dropdown daftar petugas)
    const String selectedHelpdeskId = "HD-09";

    setState(() => _isLoading = true);

    final success = await _apiService.assignTicketToHelpdesk(_currentTicket.id, selectedHelpdeskId);

    if (success) {
      // 1. Simpan log aktivitas ke database history via API
      await _apiService.createHistoryLog(
        ticketId: _currentTicket.id,
        message: 'Tiket ditugaskan ke Helpdesk (Status: IN PROGRESS)',
        userName: Session.currentUser?.name ?? 'Admin',
      );

      // 2. Perbarui state lokal tampilan agar sinkron dengan database
      setState(() {
        _currentTicket = _currentTicket.copyWith(status: TicketStatus.inProgress);
      });

      await _fetchTicketHistory(); // Refresh list tracking riwayat dari server
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil menugaskan helpdesk ke database!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui data ke server.')));
    }

    setState(() => _isLoading = false);
  }

  // ALUR 4: Proses Finish oleh Helpdesk via API (Status otomatis berubah ke Closed)
  void _handleFinishTicket() async {
    setState(() => _isLoading = true);

    final success = await _apiService.finishTicket(_currentTicket.id);

    if (success) {
      // 1. Simpan log aktivitas penutupan ke database history via API
      await _apiService.createHistoryLog(
        ticketId: _currentTicket.id,
        message: 'Pekerjaan selesai, tiket ditutup (Status: CLOSED)',
        userName: Session.currentUser?.name ?? 'Helpdesk',
      );

      // 2. Perbarui state lokal tampilan
      setState(() {
        _currentTicket = _currentTicket.copyWith(status: TicketStatus.closed);
      });

      await _fetchTicketHistory(); // Refresh list tracking riwayat dari server
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket resmi diselesaikan di database!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memproses penutupan tiket.')));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser;
    final isAdmin = user?.role == UserRole.admin;
    final isHelpdesk = user?.role == UserRole.helpdesk;
    final isClosed = _currentTicket.status == TicketStatus.closed;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTicket.id),
        leading: widget.onBack != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
            Text('Deskripsi Masalah Keluhan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_currentTicket.description),
            const Divider(height: 32),

            // AKSI TOMBOL BERDASARKAN ALUR DATABASE CLOUD (HILANG JIKA CLOSED)
            if (!isClosed) ...[
              if (isAdmin) ...[
                ElevatedButton.icon(
                  onPressed: _handleAssignHelpdesk,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign Helpdesk & Mulai Kerja (In Progress)'),
                ),
                const SizedBox(height: 16),
              ],
              if (isHelpdesk && _currentTicket.status == TicketStatus.inProgress) ...[
                ElevatedButton.icon(
                  onPressed: _handleFinishTicket,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Selesai / Finish Kerja (Set Close)'),
                ),
                const SizedBox(height: 16),
              ],
            ] else ...[
              // ATURAN NO 5: Teks info mutlak jika status tiket sudah close
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: const Text(
                  'Tiket ini sudah ditutup (Closed). Tombol kontrol dinonaktifkan. Silakan membuat tiket keluhan baru jika ada kendala layanan lainnya.',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text('Tracking / Riwayat Perjalanan Tiket (Live API)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ticketHistoryList.isEmpty
                ? const Text('Belum ada riwayat pelacakan untuk tiket ini.', style: TextStyle(color: Colors.grey))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ticketHistoryList.length,
              itemBuilder: (context, index) {
                final history = _ticketHistoryList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                          if (index != _ticketHistoryList.length - 1)
                            Container(width: 2, height: 40, color: Colors.blue.withOpacity(0.3)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(history['message'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${history['user_name']} • ${history['created_at'].toString().substring(0, 16).replaceAll('T', ' ')}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const TextField(decoration: InputDecoration(hintText: 'Tambahkan komentar...', border: OutlineInputBorder(), suffixIcon: Icon(Icons.send))),
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