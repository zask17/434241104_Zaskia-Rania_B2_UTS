import 'package:flutter/material.dart';
// import '../../models/ticket.dart';
import '../../data/session.dart';
import '../../services/api_service.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();
  String? _selectedCategory;
  String? _selectedPriority;
  bool _isSubmitting = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final String uniqueTicketId = ApiService.generateTicketId();

      // Memetakan struktur payload ke format JSON kolom tabel tickets Supabase
      final Map<String, dynamic> ticketPayload = {
        'id': uniqueTicketId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _selectedPriority?.toLowerCase() ?? 'medium',
        'category': _selectedCategory ?? 'General',
        'creator_id': Session.currentUser?.id ?? '3',
        'creator_name': Session.currentUser?.name ?? 'Regular User',
      };

      // 1. Eksekusi penyimpanan tiket baru di Supabase Cloud via REST API
      final bool ticketCreated = await _apiService.createTicket(ticketPayload);

      if (ticketCreated) {
        // 2. Tembak relasi log pembuatan awal ke tabel ticket_histories
        await _apiService.createHistoryLog(
          ticketId: uniqueTicketId,
          message: 'Tiket berhasil dibuat (Status: OPEN)',
          userName: Session.currentUser?.name ?? 'Regular User',
        );

        if (!mounted) return;
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tiket berhasil disimpan secara cloud ke Supabase!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan tiket ke server database.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tiket Baru')),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Keluhan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Harap isi judul' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                items: ['Hardware', 'Software', 'Network', 'Account'].map((String category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => (value == null) ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Prioritas', border: OutlineInputBorder()),
                items: ['Low', 'Medium', 'High'].map((String priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority));
                }).toList(),
                onChanged: (value) => setState(() => _selectedPriority = value),
                validator: (value) => (value == null) ? 'Pilih prioritas' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Masalah',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Harap isi deskripsi' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.attach_file),
                label: const Text('Lampirkan File / Gambar'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kirim Tiket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}