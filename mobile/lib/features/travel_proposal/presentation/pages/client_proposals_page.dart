import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../data/repositories/travel_proposal_repository_impl.dart';
import '../../data/services/travel_proposal_service.dart';
import '../../domain/entities/travel_proposal_summary.dart';
import '../viewmodels/client_proposals_view_model.dart';

class ClientProposalsPage extends StatefulWidget {
  const ClientProposalsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<ClientProposalsPage> createState() => _ClientProposalsPageState();
}

class _ClientProposalsPageState extends State<ClientProposalsPage> {
  late final TravelProposalRepositoryImpl _repository;
  late final ClientProposalsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _repository = TravelProposalRepositoryImpl(
      service: TravelProposalService(),
    );
    _viewModel = ClientProposalsViewModel(repository: _repository)
      ..load(token: widget.session.token);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return _viewModel.load(token: widget.session.token);
  }

  Future<void> _sendCounterProposal(
    TravelProposalSummary proposal, {
    double? initialValue,
  }) async {
    final controller = TextEditingController(
      text: (initialValue ?? proposal.valorInicial).toStringAsFixed(2),
    );

    try {
      final value = await showModalBottomSheet<double>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enviar contraproposta',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Novo valor',
                    hintText: 'Ex.: 180.00',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(
                      controller.text.trim().replaceAll(',', '.'),
                    );

                    if (parsed == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Informe um valor válido.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop(parsed);
                  },
                  child: const Text('Enviar'),
                ),
              ],
            ),
          );
        },
      );

      if (value == null || !mounted) {
        return;
      }

      await _viewModel.sendCounterProposal(
        token: widget.session.token,
        proposalId: proposal.id,
        value: value,
      );

      if (!mounted) {
        return;
      }

      if (_viewModel.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraproposta enviada.')),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _acceptNegotiation(
    ProposalNegotiationSummary negotiation,
  ) async {
    await _viewModel.acceptNegotiation(
      token: widget.session.token,
      negotiationId: negotiation.id,
    );

    if (!mounted) {
      return;
    }

    if (_viewModel.errorMessage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Solicitação aceita.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas demandas'),
          actions: [
            IconButton(
              onPressed: authViewModel.logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: Consumer<ClientProposalsViewModel>(
              builder: (context, viewModel, _) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      elevation: 0,
                      color: const Color(0xFFE8F1FB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Viagens cadastradas',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Acompanhe as ofertas dos motoristas, aceite um valor ou envie uma nova contraproposta.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (viewModel.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (viewModel.errorMessage != null)
                      _ErrorCard(
                        message: viewModel.errorMessage!,
                        onRetry: _refresh,
                      )
                    else if (viewModel.proposals.isEmpty)
                      const _EmptyStateCard()
                    else
                      ...viewModel.proposals.map(
                        (proposal) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ClientProposalCard(
                            proposal: proposal,
                            isSubmitting: viewModel.isSubmitting,
                            onCounterProposal: () =>
                                _sendCounterProposal(proposal),
                            onAcceptNegotiation: _acceptNegotiation,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientProposalCard extends StatelessWidget {
  const _ClientProposalCard({
    required this.proposal,
    required this.isSubmitting,
    required this.onCounterProposal,
    required this.onAcceptNegotiation,
  });

  final TravelProposalSummary proposal;
  final bool isSubmitting;
  final VoidCallback onCounterProposal;
  final Future<void> Function(ProposalNegotiationSummary negotiation)
  onAcceptNegotiation;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${proposal.origem} → ${proposal.destino}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        proposal.status,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: isSubmitting ? null : onCounterProposal,
                  child: const Text('Contraproposta'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Valor inicial',
              value:
                  'R\$ ${proposal.valorInicial.toStringAsFixed(2).replaceAll('.', ',')}',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Datas',
              value: _formatTravelDates(proposal),
            ),
            const SizedBox(height: 16),
            Text(
              'Propostas recebidas',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (proposal.negotiations.isEmpty)
              const Text('Nenhuma proposta recebida ainda.')
            else
              ...proposal.negotiations.map(
                (negotiation) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NegotiationTile(
                    negotiation: negotiation,
                    isOwnProposal: negotiation.senderRole == 'CLIENTE',
                    isSubmitting: isSubmitting,
                    onAccept: () => onAcceptNegotiation(negotiation),
                    onCounterProposal: onCounterProposal,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTravelDates(TravelProposalSummary proposal) {
    final ida = _formatDate(proposal.dataIda);
    final volta = _formatDate(proposal.dataVolta);

    if (volta.isEmpty) {
      return ida.isEmpty ? 'Sem data informada' : ida;
    }

    if (ida.isEmpty) {
      return volta;
    }

    return '$ida - $volta';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _NegotiationTile extends StatelessWidget {
  const _NegotiationTile({
    required this.negotiation,
    required this.isOwnProposal,
    required this.isSubmitting,
    required this.onAccept,
    required this.onCounterProposal,
  });

  final ProposalNegotiationSummary negotiation;
  final bool isOwnProposal;
  final bool isSubmitting;
  final VoidCallback onAccept;
  final VoidCallback onCounterProposal;

  @override
  Widget build(BuildContext context) {
    final isDriverOffer = negotiation.senderRole == 'MOTORISTA';
    final title = isOwnProposal ? 'Sua contraproposta' : negotiation.senderName;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                negotiation.status,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Valor ofertado: R\$ ${negotiation.valorOfertado.toStringAsFixed(2).replaceAll('.', ',')}',
          ),
          const SizedBox(height: 12),
          if (isDriverOffer)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: isSubmitting ? null : onAccept,
                  child: const Text('Aceitar valor'),
                ),
                OutlinedButton(
                  onPressed: isSubmitting ? null : onCounterProposal,
                  child: const Text('Nova contraproposta'),
                ),
              ],
            )
          else
            const Text('Aguardando resposta do motorista.'),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Nenhuma demanda cadastrada ainda.'),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFF1F1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Não foi possível carregar suas demandas.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E6F5C)),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
