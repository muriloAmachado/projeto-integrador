import '../repositories/auth_repository.dart';

class RegisterUseCase {
  RegisterUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call({
    required String nome,
    required String email,
    required String password,
    required String role,
  }) =>
      _authRepository.register(nome: nome, email: email, password: password, role: role);
}
