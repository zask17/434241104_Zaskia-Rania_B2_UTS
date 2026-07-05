enum UserRole { admin, helpdesk, user }

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role.name,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    String roleString = 'user';

    // Handle response dari Supabase dengan join `select=*,roles(role_name)`
    // Response akan berbentuk: { ..., "roles": { "role_name": "admin" } }
    final rolesData = json['roles'];
    if (rolesData != null) {
      if (rolesData is Map && rolesData['role_name'] != null) {
        roleString = rolesData['role_name'].toString();
      } else if (rolesData is List && rolesData.isNotEmpty) {
        roleString = (rolesData[0] as Map)['role_name']?.toString() ?? 'user';
      }
    } else if (json['role'] != null) {
      // Fallback jika field 'role' langsung ada di response
      roleString = json['role'].toString();
    } else if (json['role_id'] != null) {
      // Fallback: map role_id ke role_name
      final roleId = json['role_id'] is int ? json['role_id'] : int.tryParse(json['role_id'].toString());
      if (roleId == 1) {
        roleString = 'admin';
      } else if (roleId == 2) {
        roleString = 'helpdesk';
      } else {
        roleString = 'user';
      }
    }

    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name.toLowerCase() == roleString.toLowerCase(),
        orElse: () => UserRole.user,
      ),
    );
  }

  /// Cek apakah user adalah admin
  bool get isAdmin => role == UserRole.admin;

  /// Cek apakah user adalah helpdesk
  bool get isHelpdesk => role == UserRole.helpdesk;

  /// Cek apakah user adalah staff (admin atau helpdesk)
  bool get isStaff => role == UserRole.admin || role == UserRole.helpdesk;

  /// Cek apakah user adalah regular user
  bool get isRegularUser => role == UserRole.user;
}
