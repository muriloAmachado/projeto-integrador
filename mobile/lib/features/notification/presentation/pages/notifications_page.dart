import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/services/notification_service.dart';
import '../../domain/entities/app_notification.dart';
import '../viewmodels/notifications_view_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with WidgetsBindingObserver {
  late final NotificationsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = NotificationsViewModel(
      repository: NotificationRepositoryImpl(service: NotificationService()),
    )..load(token: widget.session.token);
    _viewModel.startPolling(token: widget.session.token);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pausa o polling em segundo plano e retoma (com refresh) ao voltar.
    if (state == AppLifecycleState.resumed) {
      _viewModel.load(token: widget.session.token);
      _viewModel.startPolling(token: widget.session.token);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _viewModel.stopPolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _viewModel.load(token: widget.session.token);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Notificações'),
          actions: [
            Consumer<NotificationsViewModel>(
              builder: (context, viewModel, _) {
                if (viewModel.unreadCount == 0) {
                  return const SizedBox.shrink();
                }
                return TextButton(
                  onPressed: () =>
                      viewModel.markAllAsRead(token: widget.session.token),
                  child: const Text('Marcar todas'),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: Consumer<NotificationsViewModel>(
              builder: (context, viewModel, _) {
                if (viewModel.isLoading && viewModel.notifications.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.errorMessage != null &&
                    viewModel.notifications.isEmpty) {
                  return _MessageState(
                    icon: Icons.error_outline_rounded,
                    title: 'Não foi possível carregar',
                    message: viewModel.errorMessage!,
                  );
                }

                if (viewModel.notifications.isEmpty) {
                  return const _MessageState(
                    icon: Icons.notifications_none_rounded,
                    title: 'Nenhuma notificação',
                    message: 'Você será avisado por aqui sobre suas viagens.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notification = viewModel.notifications[index];
                    return _NotificationCard(
                      notification: notification,
                      onTap: notification.lida
                          ? null
                          : () => viewModel.markAsRead(
                                token: widget.session.token,
                                id: notification.id,
                              ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.lida;
    final accent = _accentColor(notification.tipo);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unread ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: unread ? const Color(0xFFBFDBFE) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(notification.tipo), color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.titulo,
                          style: TextStyle(
                            fontWeight:
                                unread ? FontWeight.w800 : FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.mensagem,
                    style: const TextStyle(color: Color(0xFF475569)),
                  ),
                  if (notification.criadoEm != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.criadoEm!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentColor(String tipo) {
    switch (tipo) {
      case 'NEGOTIATION_ACCEPTED':
        return const Color(0xFF059669);
      case 'NEGOTIATION_CREATED':
        return const Color(0xFFF59E0B);
      case 'PROPOSAL_CREATED':
      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData _iconFor(String tipo) {
    switch (tipo) {
      case 'NEGOTIATION_ACCEPTED':
        return Icons.check_circle_rounded;
      case 'NEGOTIATION_CREATED':
        return Icons.local_offer_rounded;
      case 'PROPOSAL_CREATED':
      default:
        return Icons.directions_bus_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
          child: Column(
            children: [
              Icon(icon, size: 64, color: const Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
