import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../features/client/home/client_home_page.dart';
import '../features/driver/home/driver_home_page.dart';
import '../features/auth/domain/entities/auth_session.dart';

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Projeto Integrador',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F4C81)),
        useMaterial3: true,
      ),
      home: Consumer<AuthViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isBootstrapping) {
            return const _SplashScreen();
          }

          final session = viewModel.session;
          if (session == null) {
            return const LoginPage();
          }

          switch (session.role) {
            case UserRole.client:
              return ClientHomePage(session: session);
            case UserRole.driver:
              return DriverHomePage(session: session);
            case UserRole.admin:
            case UserRole.unknown:
              return const _UnsupportedRolePage();
          }
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _UnsupportedRolePage extends StatelessWidget {
  const _UnsupportedRolePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Perfil sem home dedicada nesta versão.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}