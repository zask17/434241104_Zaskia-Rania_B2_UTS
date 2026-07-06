import 'dart:io';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
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
  List<dynamic> _ticketCommentList = [];
  final TextEditingController _commentController = TextEditingController();

  // State bantuan untuk fitur membalas komentar
  String? _replyToUser;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    _fetchTicketHistory();
    _fetchTicketComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchTicketHistory() async {
    try {
      final response = await _apiService.getTicketHistory(_currentTicket.id);
      if (response != null) {
        setState(() {
          _ticketHistoryList = response;
        });
      }
    } catch (e) {
      debugPrint('Error fetching history from API: $e');
    }
  }

  Future<void> _fetchTicketComments() async {
    try {
      final response = await _apiService.getTicketComments(_currentTicket.id);
      if (response != null) {
        setState(() {
          _ticketCommentList = response;
        });
      }
    } catch (e) {
      debugPrint('Error fetching comments from API: $e');
    }
  }

  void _handleSendComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final currentUserName = Session.currentUser?.name ?? 'User';

    // Jika sedang membalas seseorang, sisipkan tag nama di depannya
    final finalCommentText = _replyToUser != null
        ? '[Membalas $_replyToUser]: $commentText'
        : commentText;

    final success = await _apiService.createComment(
      ticketId: _currentTicket.id,
      text: finalCommentText,
      userName: currentUserName,
    );

    if (success) {
      _commentController.clear();
      setState(() {
        _replyToUser = null; // Reset status reply setelah terkirim
      });
      _fetchTicketComments();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim komentar.')),
      );
    }
  }

  // Aksi Admin: Mengubah status dari 'open' ke 'inProgress' dan menugaskan helpdesk
  void _handleAssignToHelpdesk() async {
    setState(() => _isLoading = true);
    const String helpdeskStaffId = "2";

    try {
      final success = await _apiService.assignTicketToHelpdesk(_currentTicket.id, helpdeskStaffId);

      if (success) {
        await _apiService.createHistoryLog(
          ticketId: _currentTicket.id,
          message: 'Admin menugaskan tiket ke Helpdesk (Status: In Progress)',
          userName: Session.currentUser?.name ?? 'Admin',
        );

        setState(() {
          _currentTicket = _currentTicket.copyWith(
            status: TicketStatus.inProgress,
            helpdeskId: helpdeskStaffId,
          );
        });
        await _fetchTicketHistory();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tiket berhasil ditugaskan ke Helpdesk Staff!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menugaskan tiket.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Error assigning ticket: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Aksi Helpdesk: Menutup tiket secara permanen ('closed') langsung dari 'inProgress'
  void _handleFinishTicket() async {
    setState(() => _isLoading = true);

    final success = await _apiService.finishTicket(_currentTicket.id);

    if (success) {
      await _apiService.createHistoryLog(
        ticketId: _currentTicket.id,
        message: 'Pekerjaan selesai oleh Helpdesk, tiket ditutup permanen (Status: CLOSED)',
        userName: Session.currentUser?.name ?? 'Helpdesk',
      );

      setState(() {
        _currentTicket = _currentTicket.copyWith(status: TicketStatus.closed);
      });

      await _fetchTicketHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiket resmi diselesaikan dan dikunci di database!'),
          backgroundColor: Colors.grey,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memproses penutupan tiket.'), backgroundColor: Colors.red),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser;
    final isAdmin = user?.role == UserRole.admin;
    final isHelpdesk = user?.role == UserRole.helpdesk;

    final isOpen = _currentTicket.status == TicketStatus.open;
    final isInProgress = _currentTicket.status == TicketStatus.inProgress;
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
            const SizedBox(height: 16),

            // 📸 INTEGRASI: MENAMPILKAN FOTO YANG DIKIRIM DI TIKET
            if (_currentTicket.attachments.isNotEmpty) ...[
              Text('Lampiran Foto Keluhan:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _currentTicket.attachments.map((fileSource) {
                  final isNetworkUrl = fileSource.startsWith('http://') || fileSource.startsWith('https://');

                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isNetworkUrl
                          ? Image.network(
                        fileSource,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      )
                          : kIsWeb
                          ? const Center(child: Icon(Icons.insert_drive_file, color: Colors.blue))
                          : Image.file(
                        File(fileSource),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const Divider(height: 32),

            // ALUR KONTROL STATUS TERBARU (RESOLVED DIHAPUS)
            if (!isClosed) ...[
              // 1. Aksi Admin mengalihkan dari OPEN -> IN PROGRESS
              if (isAdmin && isOpen) ...[
                ElevatedButton.icon(
                  onPressed: _handleAssignToHelpdesk,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.assignment_ind),
                  label: const Text('Assign ke Staff Helpdesk (Set In Progress)'),
                ),
                const SizedBox(height: 16),
              ],

              // 2. Aksi Helpdesk langsung menutup tiket dari IN PROGRESS -> CLOSED
              if (isHelpdesk && isInProgress) ...[
                ElevatedButton.icon(
                  onPressed: _handleFinishTicket,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Selesai / Finish Kerja (Set Close Tiket)'),
                ),
                const SizedBox(height: 16),
              ],
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Tiket ini telah diselesaikan & ditutup (Closed). Sesi kontrol dihentikan.',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text('Tracking / Riwayat Perjalanan Tiket (Live API)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ticketHistoryList.isEmpty
                ? const Text('Belum ada riwayat pelacakan.', style: TextStyle(color: Colors.grey))
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
                            Container(width: 2, height: 40, color: Colors.blue.withValues(alpha: 0.3)),
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

            const Divider(height: 32),
            Text('Komentar Tiket Keluhan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _ticketCommentList.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Belum ada diskusi komentar.', style: TextStyle(color: Colors.grey)),
            )
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ticketCommentList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final comment = _ticketCommentList[index];
                final commentText = comment['comment_text'] ?? '';
                final isReply = commentText.startsWith('[Membalas');

                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: isReply ? const EdgeInsets.only(left: 24) : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: isReply ? Colors.blue.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: isReply ? Border.all(color: Colors.blue.withValues(alpha: 0.1)) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(comment['user_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          Text(
                            comment['created_at'].toString().substring(0, 16).replaceAll('T', ' '),
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(commentText),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _replyToUser = comment['user_name'];
                            });
                          },
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                          icon: const Icon(Icons.reply, size: 14, color: Colors.grey),
                          label: const Text('Balas', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            if (_replyToUser != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.amber.withValues(alpha: 0.15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Membalas komentar dari: $_replyToUser', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    GestureDetector(
                      onTap: () => setState(() => _replyToUser = null),
                      child: const Icon(Icons.cancel, size: 16, color: Colors.grey),
                    )
                  ],
                ),
              ),

            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: _replyToUser != null ? 'Tulis balasan...' : 'Tambahkan komentar...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _handleSendComment,
                ),
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
      case TicketStatus.closed: color = Colors.grey; text = 'Closed'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}