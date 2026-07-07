import 'dart:io';
import 'dart:convert'; // Diperlukan untuk enkripsi Base64
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  File? _selectedImage;          // Untuk Mobile path tracking
  Uint8List? _webImageBytes;     // Untuk menyimpan bytes gambar
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Ambil bytes data gambar agar support di Web maupun Mobile
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _selectedImage = File(pickedFile.name); // Simpan referensi nama objek
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil gambar.')),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _webImageBytes = null;
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // 💡 KOREKSI: Tambahkan 'await' karena ID sekarang dicek langsung ke Live Database
      final String uniqueTicketId = await _apiService.generateTicketId();

      List<String> attachmentsList = [];

      // Konversi bytes gambar menjadi format Base64 standard URI scheme
      if (_webImageBytes != null) {
        String base64Image = base64Encode(_webImageBytes!).replaceAll('\n', '').replaceAll('\r', '');
        attachmentsList.add("data:image/png;base64,$base64Image");
      }

      final Map<String, dynamic> ticketPayload = {
        'id': uniqueTicketId, // ID berurutan hasil query (Contoh: TKT-260707001)
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _selectedPriority?.toLowerCase() ?? 'medium',
        'category': _selectedCategory ?? 'General',
        'creator_id': Session.currentUser?.id ?? '3',
        'creator_name': Session.currentUser?.name ?? 'Regular User',
        'attachments': attachmentsList,
      };

      final bool ticketCreated = await _apiService.createTicket(ticketPayload);

      if (ticketCreated) {
        await _apiService.createHistoryLog(
          ticketId: uniqueTicketId,
          message: 'Tiket berhasil dibuat dengan lampiran (Status: OPEN)',
          userName: Session.currentUser?.name ?? 'Regular User',
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tiket berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan tiket ke server database.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (mounted) setState(() => _isSubmitting = false);
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

              _webImageBytes == null
                  ? OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.attach_file),
                label: const Text('Lampirkan Foto / Gambar'),
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
                        child: Image.memory(
                          _webImageBytes!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedImage?.path ?? 'image.png',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: _removeImage,
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