import '../models/user.dart';

class Session {
  static User? currentUser;

  static bool get isLoggedIn => currentUser != null;

  static void clear() {
    currentUser = null;
  }
}