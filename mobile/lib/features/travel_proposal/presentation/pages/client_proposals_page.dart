import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CounterProposalBottomSheet(
        initialValue: initialValue ?? proposal.valorInicial,
      ),
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
  }

  Future<void> _acceptNegotiation(
    ProposalNegotiationSummary negotiation,
  ) async {
    await _viewModel.acceptNegotiation(
      token: widget.session.token,
      negotiationId: negotiation.id,
    );

    if (!mounted) return;

    if (_viewModel.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação aceita.')),
      );
    }
  }

  Future<void> _endTrip(TravelProposalSummary proposal) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final code = await _viewModel.getTripCode(
      token: widget.session.token,
      proposalId: proposal.id,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // fecha o loading

    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage ?? 'Erro ao buscar código')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => _TripCodeDialog(code: code),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minhas demandas'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                context.read<AuthViewModel>().logout();
              },
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
                        (proposal) {
                          final isAccepted = proposal.status
                              .toLowerCase()
                              .contains('aceit');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ClientProposalCard(
                              proposal: proposal,
                              isSubmitting: viewModel.isSubmitting,
                              onCounterProposal: isAccepted
                                  ? null
                                  : () => _sendCounterProposal(proposal),
                              onAcceptNegotiation: _acceptNegotiation,
                              onEndTrip: isAccepted
                                  ? () => _endTrip(proposal)
                                  : null,
                            ),
                          );
                        },
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
    this.onEndTrip,
  });

  final TravelProposalSummary proposal;
  final bool isSubmitting;
  final VoidCallback? onCounterProposal;
  final Future<void> Function(ProposalNegotiationSummary negotiation)
  onAcceptNegotiation;
  final VoidCallback? onEndTrip;

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
                  child: Text(
                    '${proposal.origem} → ${proposal.destino}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(status: proposal.status),
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
                    proposalAccepted: onEndTrip != null,
                    onAccept: () => onAcceptNegotiation(negotiation),
                    onCounterProposal: onCounterProposal,
                  ),
                ),
              ),
            if (onEndTrip != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isSubmitting ? null : onEndTrip,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Encerrar Viagem'),
                ),
              ),
            ],
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
    required this.proposalAccepted,
    required this.onAccept,
    required this.onCounterProposal,
  });

  final ProposalNegotiationSummary negotiation;
  final bool isOwnProposal;
  final bool isSubmitting;
  final bool proposalAccepted;
  final VoidCallback onAccept;
  final VoidCallback? onCounterProposal;

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
          if (!proposalAccepted) ...[
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
                  if (onCounterProposal != null)
                    OutlinedButton(
                      onPressed: isSubmitting ? null : onCounterProposal,
                      child: const Text('Nova contraproposta'),
                    ),
                ],
              )
            else
              const Text('Aguardando resposta do motorista.'),
          ],
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _color(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('aceit')) return const Color(0xFF10B981);
    if (lower.contains('cancel')) return const Color(0xFFEF4444);
    if (lower.contains('and')) return const Color(0xFFF59E0B);
    return const Color(0xFF64748B);
  }
}

class _TripCodeDialog extends StatelessWidget {
  const _TripCodeDialog({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flag_rounded, color: Color(0xFF059669), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Código de Encerramento',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Mostre este código ao motorista para confirmar o fim da viagem.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Color(0xFF059669),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado!')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copiar código'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _CounterProposalBottomSheet extends StatefulWidget {
  const _CounterProposalBottomSheet({required this.initialValue});

  final double initialValue;

  @override
  State<_CounterProposalBottomSheet> createState() =>
      _CounterProposalBottomSheetState();
}

class _CounterProposalBottomSheetState
    extends State<_CounterProposalBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
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
                  _controller.text.trim().replaceAll(',', '.'),
                );
                if (parsed == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe um valor válido.')),
                  );
                  return;
                }
                Navigator.of(context).pop(parsed);
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
