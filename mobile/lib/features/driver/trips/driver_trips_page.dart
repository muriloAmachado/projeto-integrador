import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/domain/entities/auth_session.dart';
import '../../travel_proposal/data/repositories/travel_proposal_repository_impl.dart';
import '../../travel_proposal/data/services/travel_proposal_service.dart';
import '../../travel_proposal/domain/entities/travel_proposal_summary.dart';
import '../../travel_proposal/presentation/viewmodels/driver_trips_view_model.dart';

class DriverTripsPage extends StatefulWidget {
  const DriverTripsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<DriverTripsPage> createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends State<DriverTripsPage> {
  late final DriverTripsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DriverTripsViewModel(
      repository: TravelProposalRepositoryImpl(service: TravelProposalService()),
    )..load(token: widget.session.token);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _viewModel.load(token: widget.session.token);

  Future<void> _finalizeTrip(String code) async {
    final success = await _viewModel.finalizeTrip(
      token: widget.session.token,
      code: code,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viagem encerrada com sucesso!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage ?? 'Código inválido'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _showFinalizeDialog(TravelProposalSummary trip) {
    final controller = TextEditingController();

    showModalBottomSheet(
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
              const Icon(Icons.flag_rounded, color: Color(0xFF059669), size: 40),
              const SizedBox(height: 12),
              Text(
                'Encerrar Viagem',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${trip.origem} → ${trip.destino}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Código fornecido pelo cliente',
                  hintText: 'Ex.: TRIP-123456',
                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  final code = controller.text.trim();
                  if (code.isEmpty) return;
                  Navigator.of(context).pop();
                  _finalizeTrip(code);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Confirmar encerramento'),
              ),
            ],
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Minhas Viagens',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Consumer<DriverTripsViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.isLoading && viewModel.trips.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.errorMessage != null && viewModel.trips.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _ErrorCard(message: viewModel.errorMessage!, onRetry: _refresh),
                  ],
                );
              }

              final accepted = viewModel.trips.where((t) => t.status == 'ACEITO').toList();
              final closed = viewModel.trips.where((t) => t.status == 'ENCERRADO').toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  _SummaryHeader(
                    totalCount: viewModel.trips.length,
                    pendingCount: accepted.length,
                  ),
                  if (viewModel.trips.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: _EmptyStateCard(),
                    )
                  else ...[
                    if (accepted.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _SectionLabel(
                        label: 'Aguardando encerramento',
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 12),
                      ...accepted.map(
                        (trip) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TripCard(
                            trip: trip,
                            isSubmitting: viewModel.isSubmitting,
                            onFinalize: () => _showFinalizeDialog(trip),
                          ),
                        ),
                      ),
                    ],
                    if (closed.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _SectionLabel(
                        label: 'Encerradas',
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(height: 12),
                      ...closed.map(
                        (trip) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TripCard(
                            trip: trip,
                            isSubmitting: false,
                            onFinalize: null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.totalCount, required this.pendingCount});

  final int totalCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car_rounded, color: Color(0xFF059669), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalCount ${totalCount == 1 ? 'viagem' : 'viagens'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  pendingCount > 0
                      ? '$pendingCount aguardando encerramento'
                      : 'Todas encerradas',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.isSubmitting,
    required this.onFinalize,
  });

  final TravelProposalSummary trip;
  final bool isSubmitting;
  final VoidCallback? onFinalize;

  bool get isAcceito => trip.status == 'ACEITO';

  double get valorAcordado {
    final aceita = trip.negotiations.where((n) => n.status == 'ACEITA').toList();
    return aceita.isNotEmpty ? aceita.first.valorOfertado : trip.valorInicial;
  }

  Color get statusColor =>
      isAcceito ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

  String get statusLabel => isAcceito ? 'ACEITO' : 'ENCERRADO';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: double.infinity, height: 4, color: statusColor),
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
                              const Icon(Icons.person_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                trip.cliente,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${trip.origem} → ${trip.destino}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InfoBlock(
                        icon: Icons.calendar_today_rounded,
                        label: 'Data',
                        value: trip.dataIda != null ? _fmt(trip.dataIda!) : '—',
                      ),
                    ),
                    Expanded(
                      child: _InfoBlock(
                        icon: Icons.payments_rounded,
                        label: 'Valor acordado',
                        value: 'R\$ ${valorAcordado.toStringAsFixed(2).replaceAll('.', ',')}',
                        valueColor: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                if (isAcceito && onFinalize != null) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Solicite o código ao cliente para encerrar a viagem.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isSubmitting ? null : onFinalize,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.vpn_key_rounded),
                      label: const Text('Encerrar Viagem'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

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
            Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
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
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB91C1C)),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: Colors.black.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhuma viagem aceita',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quando um cliente aceitar sua proposta, a viagem aparecerá aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
