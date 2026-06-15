import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/domain/entities/auth_session.dart';
import '../../auth/presentation/viewmodels/auth_view_model.dart';

class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E6F5C),
        foregroundColor: Colors.white,
        title: const Text('Home do Motorista'),
        actions: [
          IconButton(
            onPressed: authViewModel.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        color: const Color(0xFFF3FBF8),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo, ${session.email}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tela principal do motorista para visualizar demandas e negociar corridas.',
            ),
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFFDFF4EC),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aqui entra o painel de demandas disponíveis para o motorista.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}