import 'dart:async';

import 'package:flutter/material.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/services/notification_service.dart';
import '../../notification_polling.dart';
import '../pages/notifications_page.dart';

/// Ícone de sino para a AppBar com um badge de notificações não lidas.
/// Busca a contagem ao montar e a atualiza ao retornar da lista.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, required this.session});

  final AuthSession session;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with WidgetsBindingObserver {
  late final NotificationRepositoryImpl _repository;
  Timer? _pollTimer;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = NotificationRepositoryImpl(service: NotificationService());
    _loadCount();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      NotificationPolling.interval,
      (_) => _loadCount(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCount();
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopPolling();
    }
  }

  Future<void> _loadCount() async {
    try {
      final count = await _repository.unreadCount(token: widget.session.token);
      if (mounted) {
        setState(() => _unread = count);
      }
    } catch (_) {
      // Silencioso: o badge é informativo e não deve quebrar a tela.
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsPage(session: widget.session),
      ),
    );
    await _loadCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Badge.count(
      count: _unread,
      isLabelVisible: _unread > 0,
      offset: const Offset(-4, 4),
      child: IconButton(
        tooltip: 'Notificações',
        onPressed: _openNotifications,
        icon: const Icon(Icons.notifications_rounded),
      ),
    );
  }
}
