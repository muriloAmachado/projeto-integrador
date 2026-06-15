enum UserRole { client, driver, admin, unknown }

class AuthSession {
  AuthSession({
    required this.token,
    required this.userId,
    required this.email,
    required this.role,
  });

  final String token;
  final String userId;
  final String email;
  final UserRole role;

  factory AuthSession.fromJwt(String token, Map<String, dynamic> payload) {
    return AuthSession(
      token: token,
      userId: payload['id']?.toString() ?? '',
      email: payload['email']?.toString() ?? '',
      role: _roleFromRaw(payload['role']?.toString()),
    );
  }

  static UserRole _roleFromRaw(String? rawRole) {
    switch (rawRole) {
      case 'CLIENTE':
        return UserRole.client;
      case 'MOTORISTA':
        return UserRole.driver;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }
}