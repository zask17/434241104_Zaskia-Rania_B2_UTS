import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  static const String _host = 'smtp.mailtrap.io';
  static const int _port = 2525;
  static const String _username = 'ce27497bb91615';
  static const String _password = '17573a9b81a199';
  static const String _fromEmail = 'hello@example.com';
  static const String _fromName = 'Ticketing Helpdesk';

  static Future<bool> sendResetPasswordEmail(String targetEmail, String resetLink) async {
    if (kIsWeb) {
      print('--- WEB SIMULATION ---');
      print('EmailService: SMTP tidak didukung di Browser.');
      print('Mengirim link reset ke konsol untuk testing:');
      print('TARGET: $targetEmail');
      print('LINK: $resetLink');
      print('-----------------------');
      
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    print('EmailService: Memulai pengiriman email asli ke $targetEmail...');
    
    final smtpServer = SmtpServer(
      _host,
      port: _port,
      username: _username,
      password: _password,
      ssl: false,
    );

    final message = Message()
      ..from = Address(_fromEmail, _fromName)
      ..recipients.add(targetEmail)
      ..subject = 'Reset Your Password - Ticketing Helpdesk'
      ..html = """
        <div style="font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px; max-width: 600px; margin: auto;">
          <h2 style="color: #FF9900;">Reset Password</h2>
          <p>Halo,</p>
          <p>Kami menerima permintaan untuk mengatur ulang kata sandi akun Anda. Silakan klik tombol di bawah ini untuk melanjutkan:</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="$resetLink" style="background-color: #FF9900; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-weight: bold;">Reset Password</a>
          </div>
          <p>Jika Anda tidak merasa melakukan permintaan ini, silakan abaikan email ini.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="font-size: 12px; color: #999;">Email ini dikirim secara otomatis oleh sistem Ticketing Helpdesk.</p>
        </div>
      """;

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      return true;
    } catch (e) {
      print('Error sending email (Mobile): $e');
      return false;
    }
  }
}
