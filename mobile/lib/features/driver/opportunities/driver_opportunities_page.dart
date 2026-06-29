import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/domain/entities/auth_session.dart';
import '../../travel_proposal/data/repositories/travel_proposal_repository_impl.dart';
import '../../travel_proposal/data/services/travel_proposal_service.dart';
import '../../travel_proposal/domain/entities/travel_proposal_summary.dart';
import '../../travel_proposal/presentation/viewmodels/driver_proposals_view_model.dart';

class DriverOpportunitiesPage extends StatefulWidget {
  const DriverOpportunitiesPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<DriverOpportunitiesPage> createState() => _DriverOpportunitiesPageState();
}

class _DriverOpportunitiesPageState extends State<DriverOpportunitiesPage> {
  late final DriverProposalsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DriverProposalsViewModel(
      repository: TravelProposalRepositoryImpl(service: TravelProposalService()),
    )..load(token: widget.session.token);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _viewModel.load(token: widget.session.token);

  Future<void> _openNegotiationDialog(
    TravelProposalSummary proposal, {
    required double initialValue,
    required String title,
    bool blockInput = false,
  }) async {
    final controller = TextEditingController(
      text: initialValue.toStringAsFixed(2),
    );

    try {
      final value = await showModalBottomSheet<double>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 32,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Informe o valor que você deseja cobrar por esta viagem de ida e volta.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  enabled: !blockInput,
                  decoration: InputDecoration(
                    labelText: 'Valor da Proposta (R\$)',
                    hintText: '0,00',
                    prefixIcon: const Icon(Icons.payments_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(
                      controller.text.trim().replaceAll(',', '.'),
                    );
                    if (parsed == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Informe um valor válido.')),
                      );
                      return;
                    }
                    Navigator.of(context).pop(parsed);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Enviar Proposta'),
                ),
              ],
            ),
          );
        },
      );

      if (value == null || !mounted) return;

      await _viewModel.sendOffer(
        token: widget.session.token,
        proposalId: proposal.id,
        value: value,
      );

      if (!mounted) return;

      if (_viewModel.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sua proposta foi enviada com sucesso!')),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _acceptCounterProposal(ProposalNegotiationSummary negotiation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceitar contraproposta'),
        content: Text(
          'Confirmar a viagem pelo valor de '
          'R\$ ${negotiation.valorOfertado.toStringAsFixed(2).replaceAll('.', ',')}? '
          'A viagem será fechada com este grupo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _viewModel.acceptNegotiation(
      token: widget.session.token,
      negotiationId: negotiation.id,
    );

    if (!mounted) return;

    if (_viewModel.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viagem confirmada com o grupo!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Oportunidades de Viagem',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Consumer<DriverProposalsViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.isLoading && viewModel.proposals.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.errorMessage != null && viewModel.proposals.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: _ErrorCard(message: viewModel.errorMessage!, onRetry: _refresh),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _SummaryPill(
                                    label: 'Disponíveis',
                                    value: viewModel.proposals.length.toString(),
                                    icon: Icons.route_rounded,
                                  ),
                                  const SizedBox(width: 12),
                                  _SummaryPill(
                                    label: 'Status',
                                    value: viewModel.isLoading ? '...' : 'Ativo',
                                    icon: Icons.check_circle_outline_rounded,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Confira as demandas de grupos e envie seu orçamento.',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        if (viewModel.proposals.isEmpty)
                          const SliverToBoxAdapter(child: _EmptyStateCard())
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final proposal = viewModel.proposals[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ProposalCard(
                                    proposal: proposal,
                                    currentUserId: widget.session.userId,
                                    isSubmitting: viewModel.isSubmitting,
                                    onCounterProposal: () => _openNegotiationDialog(
                                      proposal,
                                      initialValue: proposal.valorInicial,
                                      title: 'Fazer Contraproposta',
                                    ),
                                    onAcceptClientValue: () => _openNegotiationDialog(
                                      proposal,
                                      initialValue: proposal.valorInicial,
                                      title: 'Aceitar Valor do Grupo',
                                      blockInput: true,
                                    ),
                                    onAcceptCounterProposal: _acceptCounterProposal,
                                  ),
                                );
                              },
                              childCount: viewModel.proposals.length,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF059669), size: 20),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.proposal,
    required this.currentUserId,
    required this.isSubmitting,
    required this.onCounterProposal,
    required this.onAcceptClientValue,
    required this.onAcceptCounterProposal,
  });

  final TravelProposalSummary proposal;
  final String currentUserId;
  final bool isSubmitting;
  final VoidCallback onCounterProposal;
  final VoidCallback onAcceptClientValue;
  final Future<void> Function(ProposalNegotiationSummary) onAcceptCounterProposal;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(proposal.status);

    final clientCounterProposals = proposal.negotiations
        .where((n) => n.senderRole == 'CLIENTE')
        .toList(growable: false);

    final ownOffers = proposal.negotiations
        .where((n) => n.senderRole == 'MOTORISTA' && n.senderId == currentUserId)
        .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
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
                          Row(
                            children: [
                              const Icon(Icons.groups_rounded, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                'Grupo de ${proposal.cliente}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${proposal.origem} → ${proposal.destino}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(label: proposal.status, color: statusColor),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _InfoBlock(
                        icon: Icons.calendar_today_rounded,
                        label: 'Datas',
                        value: _formatTravelDates(proposal),
                      ),
                    ),
                    Expanded(
                      child: _InfoBlock(
                        icon: Icons.payments_rounded,
                        label: 'Orçamento do Grupo',
                        value: _formatCurrency(proposal.valorInicial),
                        valueColor: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (clientCounterProposals.isNotEmpty || ownOffers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Negociações',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...clientCounterProposals.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NegotiationTile(
                        title: 'Contraproposta do grupo',
                        value: n.valorOfertado,
                        status: n.status,
                        canAccept: !isSubmitting && n.status == 'EM_ANALISE',
                        onAccept: () => onAcceptCounterProposal(n),
                      ),
                    ),
                  ),
                  ...ownOffers.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NegotiationTile(
                        title: 'Sua oferta enviada',
                        value: n.valorOfertado,
                        status: n.status,
                        canAccept: false,
                        onAccept: null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting ? null : onAcceptClientValue,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text('Aceitar Valor'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isSubmitting ? null : onCounterProposal,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Contraproposta'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('aceit')) return const Color(0xFF10B981);
    if (s.contains('cancel')) return const Color(0xFFEF4444);
    if (s.contains('and')) return const Color(0xFFF59E0B);
    return const Color(0xFF64748B);
  }

  String _formatCurrency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  String _formatTravelDates(TravelProposalSummary p) {
    final ida = _fmt(p.dataIda);
    final volta = _fmt(p.dataVolta);
    if (ida.isEmpty) return 'A combinar';
    if (volta.isEmpty) return ida;
    return '$ida a $volta';
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }
}

class _NegotiationTile extends StatelessWidget {
  const _NegotiationTile({
    required this.title,
    required this.value,
    required this.status,
    required this.canAccept,
    required this.onAccept,
  });

  final String title;
  final double value;
  final String status;
  final bool canAccept;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
              ),
              Text(
                status,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF059669),
            ),
          ),
          if (onAccept != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canAccept ? onAccept : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Aceitar contraproposta'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.icon, required this.label, required this.value, this.valueColor});

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Ops! Algo deu errado',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF991B1B)),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB91C1C))),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Icon(Icons.map_outlined, size: 64, color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 24),
          const Text(
            'Sem oportunidades no momento',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fique atento! Novas solicitações de grupos aparecerão aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
