import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/storage/session_storage.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/services/auth_service.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/presentation/viewmodels/auth_view_model.dart';

void main() {
  final sessionStorage = SessionStorage();
  final authService = AuthService();
  final authRepository = AuthRepositoryImpl(
    authService: authService,
    sessionStorage: sessionStorage,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(
        loginUseCase: LoginUseCase(authRepository),
        registerUseCase: RegisterUseCase(authRepository),
        authRepository: authRepository,
      )..bootstrap(),
      child: const TravelApp(),
    ),
  );
}