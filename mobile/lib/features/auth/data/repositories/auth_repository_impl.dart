import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../../core/storage/session_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthService authService,
    required SessionStorage sessionStorage,
  })  : _authService = authService,
        _sessionStorage = sessionStorage;

  final AuthService _authService;
  final SessionStorage _sessionStorage;

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    final response = await _authService.login(email: email, password: password);
    final payload = JwtDecoder.decode(response.token);
    final session = AuthSession.fromJwt(response.token, payload);

    await _sessionStorage.saveToken(session.token);
    return session;
  }

  @override
  Future<AuthSession?> currentSession() async {
    final token = await _sessionStorage.readToken();
    if (token == null || token.isEmpty || JwtDecoder.isExpired(token)) {
      return null;
    }

    final payload = JwtDecoder.decode(token);
    return AuthSession.fromJwt(token, payload);
  }

  @override
  Future<void> logout() => _sessionStorage.clear();
}