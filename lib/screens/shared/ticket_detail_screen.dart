import 'dart:io';
import 'dart:convert'; // Diperlukan untuk decode Base64
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../data/session.dart';
import '../../services/api_service.dart';
import '../../data/theme_settings.dart';
import '../../theme/app_theme.dart' show AppColors;

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
      if (response != null) setState(() => _ticketHistoryList = response);
    } catch (e) { debugPrint('Error: $e'); }
  }

  Future<void> _fetchTicketComments() async {
    try {
      final response = await _apiService.getTicketComments(_currentTicket.id);
      if (response != null) setState(() => _ticketCommentList = response);
    } catch (e) { debugPrint('Error: $e'); }
  }

  void _handleSendComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final currentUserName = Session.currentUser?.name ?? 'User';
    final finalCommentText = _replyToUser != null ? '[Membalas $_replyToUser]: $commentText' : commentText;

    final success = await _apiService.createComment(
      ticketId: _currentTicket.id,
      text: finalCommentText,
      userName: currentUserName,
    );

    if (success) {
      _commentController.clear();
      setState(() => _replyToUser = null);
      _fetchTicketComments();
    }
  }

  void _handleAssignToHelpdesk() async {
    setState(() => _isLoading = true);
    const String helpdeskStaffId = "2";
    try {
      final success = await _apiService.assignTicketToHelpdesk(_currentTicket.id, helpdeskStaffId);
      if (success) {
        await _apiService.createHistoryLog(
          ticketId: _currentTicket.id,
          message: 'Status diubah menjadi INPROGRESS',
          userName: Session.currentUser?.name ?? 'Admin Ticketing',
        );
        setState(() {
          _currentTicket = _currentTicket.copyWith(status: TicketStatus.inProgress, helpdeskId: helpdeskStaffId);
        });
        await _fetchTicketHistory();
      }
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _handleFinishTicket() async {
    setState(() => _isLoading = true);
    final success = await _apiService.finishTicket(_currentTicket.id);
    if (success) {
      await _apiService.createHistoryLog(
        ticketId: _currentTicket.id,
        message: 'Pekerjaan selesai oleh Helpdesk, tiket ditutup (Status: CLOSED)',
        userName: Session.currentUser?.name ?? 'Helpdesk',
      );
      setState(() { _currentTicket = _currentTicket.copyWith(status: TicketStatus.closed); });
      await _fetchTicketHistory();
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

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeSettings.themeMode,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark ||
            (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

        final dynamicBgDeep = isDark ? AppColors.bgDeep : const Color(0xFFF4F6F9);
        final dynamicSurface = isDark ? AppColors.surface : Colors.white;
        final dynamicBorder = isDark ? AppColors.border : const Color(0xFFCBD5E1);
        final dynamicTextPrimary = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
        final dynamicTextMuted = isDark ? AppColors.textMuted : const Color(0xFF64748B);

        return Scaffold(
          backgroundColor: dynamicBgDeep,
          appBar: AppBar(
            title: Text('Tiket: ${_currentTicket.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: dynamicSurface,
            foregroundColor: dynamicTextPrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: widget.onBack ?? () => Navigator.pop(context),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CARD DATA TIKET UTAMA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: dynamicSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: dynamicBorder, width: 0.8)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentTicket.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dynamicTextPrimary)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _StatusBadge(status: _currentTicket.status),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: dynamicBgDeep, borderRadius: BorderRadius.circular(6)),
                            child: Text(_currentTicket.category, style: TextStyle(color: dynamicTextMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text('Deskripsi Keluhan:', style: TextStyle(fontWeight: FontWeight.bold, color: dynamicTextPrimary, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(_currentTicket.description, style: TextStyle(color: dynamicTextPrimary, height: 1.4)),

                      // ====================================================================
                      // 📸 AREA LAMPIRAN FOTO KENDALA ADAPTIF BASE64 & NETWORK URL
                      // ====================================================================
                      if (_currentTicket.attachments.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text('Lampiran Foto Kendala:', style: TextStyle(fontWeight: FontWeight.bold, color: dynamicTextPrimary, fontSize: 13)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _currentTicket.attachments.map((fileSource) {
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: dynamicBorder, width: 0.8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Builder(
                                  builder: (context) {
                                    if (fileSource.startsWith('http')) {
                                      return Image.network(
                                        fileSource,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(child: Icon(Icons.broken_image_rounded, color: dynamicTextMuted)),
                                      );
                                    } else if (fileSource.startsWith('data:image')) {
                                      final base64Content = fileSource.split(',').last;
                                      return Image.memory(
                                        base64Decode(base64Content),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(child: Icon(Icons.broken_image_rounded, color: dynamicTextMuted)),
                                      );
                                    } else {
                                      return Image.file(
                                        File(fileSource),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(child: Icon(Icons.broken_image_rounded, color: dynamicTextMuted)),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // OPERASIONAL KONTROL AKSI STATUS
                if (!isClosed) ...[
                  if (isAdmin && isOpen)
                    ElevatedButton.icon(
                      onPressed: _handleAssignToHelpdesk,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: AppColors.amber, foregroundColor: const Color(0xFF121824), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.assignment_ind_rounded),
                      label: const Text('Assign ke Staff Helpdesk', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  if (isHelpdesk && isInProgress)
                    ElevatedButton.icon(
                      onPressed: _handleFinishTicket,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF4ADE80), foregroundColor: const Color(0xFF121824), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Selesaikan & Tutup Tiket', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF94A3B8).withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF94A3B8).withOpacity(0.3))),
                    child: const Text('Tiket ini telah dikunci (Closed). Operasional dihentikan.', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic, fontSize: 12), textAlign: TextAlign.center),
                  ),
                ],
                const SizedBox(height: 24),

                // 🕒 TRACKING / RIWAYAT PERJALANAN TIKET VERTIKAL TIMELINE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: dynamicSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: dynamicBorder, width: 0.8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tracking / Riwayat Perjalanan Tiket', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: dynamicTextPrimary)),
                      const SizedBox(height: 16),
                      _ticketHistoryList.isEmpty
                          ? Text('Belum ada data riwayat pelacakan.', style: TextStyle(color: dynamicTextMuted, fontSize: 13, fontStyle: FontStyle.italic))
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ticketHistoryList.length,
                        itemBuilder: (context, index) {
                          final history = _ticketHistoryList[index];
                          final rawTime = history['created_at']?.toString() ?? '';
                          final formattedTime = rawTime.length > 16
                              ? rawTime.substring(0, 16).replaceAll('T', ' ')
                              : rawTime;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.amber, size: 20),
                                  if (index != _ticketHistoryList.length - 1)
                                    Container(width: 2, height: 36, color: AppColors.amber.withOpacity(0.3)),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(history['message'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: dynamicTextPrimary, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text('${history['user_name']} • $formattedTime', style: TextStyle(color: dynamicTextMuted, fontSize: 11)),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // DISKUSI KOMENTAR TIKET
                Text('Diskussion / Komentar Kendala', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: dynamicTextPrimary)),
                const SizedBox(height: 12),
                _ticketCommentList.isEmpty
                    ? Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Belum ada diskusi komentar.', style: TextStyle(color: dynamicTextMuted)))
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
                      margin: isReply ? const EdgeInsets.only(left: 20) : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: dynamicSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isReply ? AppColors.amber.withOpacity(0.3) : dynamicBorder, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(comment['user_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.amber, fontSize: 13)),
                              Text(comment['created_at'].toString().substring(0, 16).replaceAll('T', ' '), style: TextStyle(color: dynamicTextMuted, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(commentText, style: TextStyle(color: dynamicTextPrimary, fontSize: 13)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => setState(() => _replyToUser = comment['user_name']),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 24)),
                              child: Text('Balas', style: TextStyle(fontSize: 11, color: dynamicTextMuted)),
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
                    decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Membalas komentar: $_replyToUser', style: TextStyle(fontSize: 12, color: dynamicTextPrimary)),
                        GestureDetector(onTap: () => setState(() => _replyToUser = null), child: Icon(Icons.cancel_rounded, size: 16, color: dynamicTextMuted))
                      ],
                    ),
                  ),

                // INPUT KOLOM KOMENTAR ADAPTIF
                TextField(
                  controller: _commentController,
                  style: TextStyle(color: dynamicTextPrimary),
                  decoration: InputDecoration(
                    hintText: _replyToUser != null ? 'Tulis balasan...' : 'Tambahkan komentar...',
                    hintStyle: TextStyle(color: dynamicTextMuted),
                    filled: true,
                    fillColor: dynamicSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dynamicBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dynamicBorder)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.amber, width: 1.4),
                    ),
                    suffixIcon: IconButton(icon: const Icon(Icons.send_rounded, color: AppColors.amber), onPressed: _handleSendComment),
                  ),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color, width: 0.8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}