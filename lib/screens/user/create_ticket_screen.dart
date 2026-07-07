import 'dart:io';
import 'dart:convert'; // Diperlukan untuk enkripsi Base64
import 'package:flutter/material.dart';

// 🔥 KOREKSI DI SINI: Berikan alias 'fp' agar tidak bentrok dengan scope global Web
import 'package:file_picker/file_picker.dart' as fp;

import '../../data/session.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
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

  String? _fileName;             // Menyimpan nama berkas dokumen/foto
  Uint8List? _fileBytes;         // Menyimpan data biner berkas
  String? _fileExtension;        // Ekstensi berkas untuk pratinjau tipe

  Future<void> _pickFile() async {
    try {
      // 🔥 KOREKSI DI SINI: Gunakan alias fp.FilePicker
      fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        withData: true, // Sangat penting agar bytes terbaca di semua platform (Web & Mobile)
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        setState(() {
          _fileName = pickedFile.name;
          _fileBytes = pickedFile.bytes;
          _fileExtension = pickedFile.extension?.toLowerCase();
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil file.')),
      );
    }
  }

  void _removeFile() {
    setState(() {
      _fileName = null;
      _fileBytes = null;
      _fileExtension = null;
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final String uniqueTicketId = await _apiService.generateTicketId();
      String? attachmentString;

      // Konversi berkas menjadi biner Base64 dengan header tipe dinamis
      if (_fileBytes != null && _fileName != null) {
        String base64Data = base64Encode(_fileBytes!);

        // Deteksi header MIME type sederhana berdasarkan ekstensi berkas
        String mimeHeader = "data:application/octet-stream";
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(_fileExtension)) {
          mimeHeader = "data:image/png"; // Dianggap gambar
        } else if (_fileExtension == 'pdf') {
          mimeHeader = "data:application/pdf";
        }

        // Hasil string tunggal: data:image/png;base64,iVBORw0KG...
        attachmentString = "$mimeHeader;base64,$base64Data";
      }

      final Map<String, dynamic> ticketPayload = {
        'id': uniqueTicketId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _selectedPriority?.toLowerCase() ?? 'medium',
        'category': _selectedCategory ?? 'General',
        'creator_id': Session.currentUser?.id ?? '3',
        'creator_name': Session.currentUser?.name ?? 'Anonymous User',
        'attachment_url': attachmentString,
      };

      final bool ticketCreated = await _apiService.createTicket(ticketPayload);

      if (ticketCreated) {
        await _apiService.createHistoryLog(
          ticketId: uniqueTicketId,
          message: 'Tiket berhasil dibuat dengan lampiran berkas (Status: OPEN)',
          userName: Session.currentUser?.name ?? 'System',
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiket berhasil disimpan!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan tiket ke server database.'), backgroundColor: Colors.red),
        );
      }

      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(_fileExtension);

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
                decoration: const InputDecoration(labelText: 'Judul Keluhan', border: OutlineInputBorder()),
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
                decoration: const InputDecoration(labelText: 'Deskripsi Masalah', border: OutlineInputBorder(), alignLabelWithHint: true),
                validator: (value) => (value == null || value.isEmpty) ? 'Harap isi deskripsi' : null,
              ),
              const SizedBox(height: 16),

              _fileBytes == null
                  ? OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Lampirkan File Dokumen / Foto'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              )
                  : Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: isImage
                            ? Image.memory(_fileBytes!, width: 70, height: 70, fit: BoxFit.cover)
                            : Container(
                          width: 70, height: 70, color: Colors.orange.withOpacity(0.1),
                          child: const Icon(Icons.insert_drive_file_rounded, color: Colors.orange, size: 36),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fileName ?? 'Berkas Terlampir',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: _removeFile,
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
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