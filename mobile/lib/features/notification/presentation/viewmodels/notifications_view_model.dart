import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../notification_polling.dart';

class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel({required NotificationRepositoryImpl repository})
    : _repository = repository;

  final NotificationRepositoryImpl _repository;

  List<AppNotification> notifications = const [];
  bool isLoading = false;
  String? errorMessage;
  Timer? _pollTimer;

  int get unreadCount => notifications.where((n) => !n.lida).length;

  Future<void> load({required String token}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      notifications = await _repository.list(token: token);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia o polling periódico que atualiza a lista em segundo plano,
  /// sem exibir o indicador de carregamento.
  void startPolling({required String token}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      NotificationPolling.interval,
      (_) => _silentRefresh(token: token),
    );
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _silentRefresh({required String token}) async {
    try {
      notifications = await _repository.list(token: token);
      errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Mantém os dados atuais; uma falha pontual de rede não limpa a lista.
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> markAsRead({
    required String token,
    required String id,
  }) async {
    try {
      await _repository.markAsRead(token: token, id: id);
      _replace(id);
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead({required String token}) async {
    try {
      await _repository.markAllAsRead(token: token);
      notifications = notifications
          .map((n) => n.lida ? n : _copyAsRead(n))
          .toList(growable: false);
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  void _replace(String id) {
    notifications = notifications
        .map((n) => n.id == id && !n.lida ? _copyAsRead(n) : n)
        .toList(growable: false);
  }

  AppNotification _copyAsRead(AppNotification n) {
    return AppNotification(
      id: n.id,
      tipo: n.tipo,
      titulo: n.titulo,
      mensagem: n.mensagem,
      lida: true,
      criadoEm: n.criadoEm,
      data: n.data,
    );
  }
}
