import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required LoginUseCase loginUseCase,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _authRepository = authRepository;

  final LoginUseCase _loginUseCase;
  final AuthRepository _authRepository;

  AuthSession? session;
  bool isBootstrapping = true;
  bool isLoading = false;
  String? errorMessage;

  Future<void> bootstrap() async {
    session = await _authRepository.currentSession();
    isBootstrapping = false;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      session = await _loginUseCase(email: email, password: password);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    session = null;
    notifyListeners();
  }
}