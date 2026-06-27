class AppNotification {
  AppNotification({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    required this.lida,
    required this.criadoEm,
    this.data = const {},
  });

  final String id;
  final String tipo;
  final String titulo;
  final String mensagem;
  final bool lida;
  final DateTime? criadoEm;
  final Map<String, dynamic> data;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'UNKNOWN',
      titulo: json['titulo']?.toString() ?? '',
      mensagem: json['mensagem']?.toString() ?? '',
      lida: json['lida'] == true,
      criadoEm: _parseDate(json['criado_em'] ?? json['criadoEm']),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : const {},
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
