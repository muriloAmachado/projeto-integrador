import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:projeto_integrador_mobile/app/app.dart';
import 'package:projeto_integrador_mobile/core/storage/session_storage.dart';
import 'package:projeto_integrador_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:projeto_integrador_mobile/features/auth/data/services/auth_service.dart';
import 'package:projeto_integrador_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:projeto_integrador_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:projeto_integrador_mobile/features/auth/presentation/viewmodels/auth_view_model.dart';

void main() {
  testWidgets('shows the login screen when there is no session', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final sessionStorage = SessionStorage();
    final authService = AuthService();
    final authRepository = AuthRepositoryImpl(
      authService: authService,
      sessionStorage: sessionStorage,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(
          loginUseCase: LoginUseCase(authRepository),
          registerUseCase: RegisterUseCase(authRepository),
          authRepository: authRepository,
        )..bootstrap(),
        child: const TravelApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bem Vindo'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
