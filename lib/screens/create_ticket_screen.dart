import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../data/dummy_data.dart';
import '../data/session.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _selectedPriority;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // 1. Tentukan Priority Enum
      TicketPriority priority = TicketPriority.medium;
      if (_selectedPriority == 'Low') priority = TicketPriority.low;
      if (_selectedPriority == 'High') priority = TicketPriority.high;

      // 2. Buat objek Tiket baru
      final newTicket = Ticket(
        id: 'TKT-00${DummyData.tickets.length + 1}',
        title: _titleController.text,
        description: _descriptionController.text,
        status: TicketStatus.open,
        priority: priority,
        category: _selectedCategory ?? 'General',
        createdAt: DateTime.now(),
        creatorId: Session.currentUser?.id ?? '3',
        creatorName: Session.currentUser?.name ?? 'Regular User',
        history: [
          TicketHistory(
            message: 'Tiket berhasil dibuat',
            timestamp: DateTime.now(),
            userName: Session.currentUser?.name ?? 'Regular User',
          ),
        ],
      );

      // 3. Tambahkan ke list global DummyData
      DummyData.tickets.insert(0, newTicket);

      // 4. Kembali ke halaman sebelumnya
      Navigator.pop(context, true); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiket berhasil dibuat dan ditambahkan ke daftar'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tiket Baru')),
      body: SingleChildScrollView(
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
