import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/ticket.dart';

class ApiService {
  // 1. Konfigurasi Endpoint & Anon Key Supabase
  static const String baseUrl = 'https://azgcylimfoggyiihpnib.supabase.co/rest/v1';
  static const String anonKey = 'sb_publishable_jvyp0o4ijJLjP0IQJRmkJQ__83qa3uf';

  /// Helper untuk mengenerate ID unik user dengan pola USR- dan 12 digit urutan angka
  Future<String> generateUserId() async {
    int nextSequence = 1;

    try {
      // Query ke Supabase untuk mengambil semua data user guna menghitung jumlah totalnya
      final uri = Uri.parse('$baseUrl/users?select=id');
      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> allUsers = jsonDecode(response.body);
        // Nomor urut berikutnya adalah total user terdaftar saat ini + 1
        nextSequence = allUsers.length + 1;
      }
    } catch (e) {
      print('Error counting total users: $e');
      // Fallback cadangan acak 8 digit jika koneksi internet mendadak putus/gagal
      nextSequence = 10000000 + Random().nextInt(89999999);
    }

    // Format urutan menjadi 8 digit dengan padLeft (Contoh: 1 -> 00000001)
    final sequenceStr = nextSequence.toString().padLeft(8, '0');

    return 'USR-$sequenceStr';
  }

  /// Helper untuk mengenerate ID unik tiket dengan pola TKT-YYYYMMDD + 4 digit no urut
  Future<String> generateTicketId() async {
    final now = DateTime.now();

    // Format tanggal untuk ID: YYMMDD (Dua digit terakhir tahun, bulan, hari)
    final yy = now.year.toString().substring(2);
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final datePattern = '$yy$mm$dd'; // Contoh: 260707

    // Format ISO awal hari ini untuk filter di database (YYYY-MM-DD)
    final todayStart = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T00:00:00.000Z";

    int nextSequence = 1;

    try {
      // Query ke Supabase untuk menghitung jumlah tiket yang dibuat sejak awal hari ini
      final uri = Uri.parse('$baseUrl/tickets').replace(queryParameters: {
        'created_at': 'gte.$todayStart',
        'select': 'id', // Cukup ambil ID saja untuk menghemat bandwidth
      });

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> ticketsToday = jsonDecode(response.body);
        // Urutan berikutnya adalah jumlah tiket hari ini + 1
        nextSequence = ticketsToday.length + 1;
      }
    } catch (e) {
      print('Error counting today\'s tickets: $e');
      nextSequence = 100 + Random().nextInt(899);
    }

    // Pad angka urutan menjadi 3 digit (Contoh: 1 -> 001, 12 -> 012)
    final sequenceStr = nextSequence.toString().padLeft(3, '0');

    return 'TKT-$datePattern$sequenceStr';
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

  // ==================== NOTIFICATIONS ====================

  /// Mengambil daftar notifikasi terbaru dari database Supabase secara riil
  Future<List<dynamic>?> fetchLiveNotifications({required int roleId, required String userId}) async {
    try {
      // Filter query bertingkat sesuai hak target role / target user id
      String queryUrl = '$baseUrl/notifications?select=*&order=created_at.desc';
      if (roleId == 3) {
        queryUrl += '&target_user_id=eq.$userId';
      } else {
        queryUrl += '&target_role_id=eq.$roleId';
      }

      final response = await http.get(
        Uri.parse(queryUrl),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Fetch Live Notifications Error: $e');
      return null;
    }
  }
}