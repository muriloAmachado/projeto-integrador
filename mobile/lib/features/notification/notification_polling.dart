/// Configuração do polling automático de notificações.
///
/// O intervalo pode ser ajustado em tempo de build via:
/// `flutter run --dart-define=NOTIFICATION_POLLING_SECONDS=15`
class NotificationPolling {
  const NotificationPolling._();

  static const int _seconds = int.fromEnvironment(
    'NOTIFICATION_POLLING_SECONDS',
    defaultValue: 10,
  );

  static const Duration interval = Duration(seconds: _seconds);
}
