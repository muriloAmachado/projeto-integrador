import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/domain/entities/auth_session.dart';
import '../../auth/presentation/viewmodels/auth_view_model.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home do Cliente'),
        actions: [
          IconButton(
            onPressed: authViewModel.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
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
              'Tela principal do cliente para cadastrar demandas de viagem e acompanhar propostas.',
            ),
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFFE8F1FB),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aqui entra o fluxo de cadastro da demanda de viagem.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}