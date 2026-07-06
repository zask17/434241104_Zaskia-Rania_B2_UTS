import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ticket.dart';

class ApiService {
  // 1. Konfigurasi Endpoint & Anon Key Supabase
  static const String baseUrl = 'https://azgcylimfoggyiihpnib.supabase.co/rest/v1';
  static const String anonKey = 'sb_publishable_jvyp0o4ijJLjP0IQJRmkJQ__83qa3uf';

  /// Helper untuk mengenerate ID unik user dengan pola USR-XXXXXX
  static String generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (timestamp % 1000000).toString().padLeft(6, '0');
    return 'USR-$randomSuffix';
  }

  /// Helper untuk mengenerate ID unik tiket dengan pola TKT-XXXXXX
  static String generateTicketId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (timestamp % 1000000).toString().padLeft(6, '0');
    return 'TKT-$randomSuffix';
  }

  /// Header standar untuk Supabase PostgREST API.
  Map<String, String> _getHeaders({String? userToken}) {
    return {
      'Content-Type': 'application/json',
      'apikey': anonKey,
      'Authorization': 'Bearer ${userToken ?? anonKey}',
      'Prefer': 'return=representation',
    };
  }

  /// Mengambil pesan error dari response body Supabase untuk debugging
  String _parseErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
      if (body is List && body.isNotEmpty && body[0] is Map && body[0]['message'] != null) {
        return body[0]['message'].toString();
      }
    } catch (_) {}
    return 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}';
  }

  // ==================== REGISTER ====================

  /// Mendaftarkan user baru ke tabel `users` di Supabase.
  Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: _getHeaders(),
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Registrasi berhasil',
          'data': data is List ? data.firstOrNull : data,
        };
      } else {
        final errorMsg = _parseErrorMessage(response);
        if (response.statusCode == 409) {
          return {
            'success': false,
            'message': 'Email sudah terdaftar. Gunakan email lain.',
          };
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          return {
            'success': false,
            'message': 'Akses ditolak oleh server. Aktifkan atau nonaktifkan RLS di Supabase Dashboard.',
          };
        }
        return {
          'success': false,
          'message': 'Registrasi gagal: $errorMsg',
        };
      }
    } catch (e) {
      print('Register User Error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      };
    }
  }

  // ==================== LOGIN ====================

  /// Login dengan mencocokkan email dan password di tabel `users`.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/users').replace(queryParameters: {
        'select': '*,roles(role_name)',
        'email': 'eq.$email',
        'password': 'eq.$password',
      });

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        if (users.isNotEmpty) {
          return {
            'success': true,
            'message': 'Login berhasil',
            'data': users.first as Map<String, dynamic>,
          };
        } else {
          return {
            'success': false,
            'message': 'Email atau password salah!',
          };
        }
      } else {
        final errorMsg = _parseErrorMessage(response);
        if (response.statusCode == 401 || response.statusCode == 403) {
          return {
            'success': false,
            'message': 'Akses ditolak oleh server. Aktifkan atau nonaktifkan RLS di Supabase Dashboard.',
          };
        }
        return {
          'success': false,
          'message': 'Gagal login: $errorMsg',
        };
      }
    } catch (e) {
      print('Login Error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      };
    }
  }

  // ==================== TICKETS ====================

  /// Mengambil daftar tiket dari Supabase (diurutkan dari terbaru)
  Future<List<Ticket>> getTickets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tickets?select=*&order=created_at.desc'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Ticket.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Get Tickets Error: $e');
      return [];
    }
  }

  /// Mengambil riwayat (ticket_histories) untuk sebuah tiket
  Future<List<dynamic>?> getTicketHistory(String ticketId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ticket_histories?ticket_id=eq.$ticketId&order=created_at.desc'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Fetch History Error: $e');
      return null;
    }
  }

  /// Menambahkan log riwayat ke tabel ticket_histories
  Future<bool> createHistoryLog({
    required String ticketId,
    required String message,
    required String userName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ticket_histories'),
        headers: _getHeaders(),
        body: jsonEncode({
          'ticket_id': ticketId,
          'message': message,
          'user_name': userName,
          'created_at': DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Create History Error: $e');
      return false;
    }
  }

  /// Membuat tiket baru (status otomatis 'open')
  Future<bool> createTicket(Map<String, dynamic> ticketData) async {
    try {
      final Map<String, dynamic> payload = {
        ...ticketData,
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/tickets'),
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Create Ticket Error: $e');
      return false;
    }
  }

  /// Assign tiket ke helpdesk dan ubah status ke 'inProgress'
  Future<bool> assignTicketToHelpdesk(String ticketId, String helpdeskId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tickets?id=eq.$ticketId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'helpdesk_id': helpdeskId,
          'status': 'inProgress',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Assign Ticket Error: $e');
      return false;
    }
  }

  /// Menyelesaikan tiket (ubah status ke 'closed')
  Future<bool> finishTicket(String ticketId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tickets?id=eq.$ticketId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'status': 'closed',
          'finished_at': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Finish Ticket Error: $e');
      return false;
    }
  }

  /// Update status tiket secara manual (custom)
  Future<bool> updateTicketStatus(String id, String status, String message) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tickets?id=eq.$id'),
        headers: _getHeaders(),
        body: jsonEncode({
          'status': status,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update Ticket Status Error: $e');
      return false;
    }
  }

  // ==================== COMMENTS ====================

  /// Mengambil semua daftar komentar berdasarkan ID tiket tertentu
  Future<List<dynamic>?> getTicketComments(String ticketId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ticket_comments?ticket_id=eq.$ticketId&order=created_at.asc'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Fetch Comments Error: $e');
      return null;
    }
  }

  /// Mengirimkan komentar baru ke tabel database Supabase
  Future<bool> createComment({
    required String ticketId,
    required String text,
    required String userName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ticket_comments'),
        headers: _getHeaders(),
        body: jsonEncode({
          'ticket_id': ticketId,
          'comment_text': text,
          'user_name': userName,
          'created_at': DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Create Comment Error: $e');
      return false;
    }
  }
} // <--- Kurung kurawal penutup kelas ApiService sekarang ada di paling bawah!