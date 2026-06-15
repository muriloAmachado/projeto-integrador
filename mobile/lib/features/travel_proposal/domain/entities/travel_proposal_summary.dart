class TravelProposalSummary {
  TravelProposalSummary({
    required this.id,
    required this.origem,
    required this.destino,
    required this.valorInicial,
    required this.dataIda,
    required this.dataVolta,
    required this.status,
    required this.cliente,
    this.negotiations = const [],
  });

  final String id;
  final String origem;
  final String destino;
  final double valorInicial;
  final DateTime? dataIda;
  final DateTime? dataVolta;
  final String status;
  final String cliente;
  final List<ProposalNegotiationSummary> negotiations;

  factory TravelProposalSummary.fromJson(Map<String, dynamic> json) {
    return TravelProposalSummary(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      origem: json['origem']?.toString() ?? '',
      destino: json['destino']?.toString() ?? '',
      valorInicial: _parseDouble(
        json['valor_inicial'] ?? json['valorInicial'] ?? json['valor'],
      ),
      dataIda: _parseDate(json['data_ida'] ?? json['dataIda']),
      dataVolta: _parseDate(json['data_volta'] ?? json['dataVolta']),
      status:
          json['status']?.toString() ??
          json['situacao']?.toString() ??
          'Pendente',
      cliente: _extractCliente(
        json['cliente'] ?? json['client'] ?? json['usuario'],
      ),
      negotiations: _parseNegotiations(json['negotiations']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }

    return 0;
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

  static String _extractCliente(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['nome']?.toString() ??
          value['email']?.toString() ??
          'Cliente';
    }

    if (value != null) {
      return value.toString();
    }

    return 'Cliente';
  }

  static List<ProposalNegotiationSummary> _parseNegotiations(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(ProposalNegotiationSummary.fromJson)
        .toList(growable: false);
  }
}

class ProposalNegotiationSummary {
  ProposalNegotiationSummary({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.valorOfertado,
    required this.status,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final double valorOfertado;
  final String status;

  factory ProposalNegotiationSummary.fromJson(Map<String, dynamic> json) {
    final sender = json['motorista'];

    return ProposalNegotiationSummary(
      id: json['id']?.toString() ?? '',
      senderId: json['motoristaId']?.toString() ?? '',
      senderName: sender is Map<String, dynamic>
          ? (sender['nome']?.toString() ??
                sender['email']?.toString() ??
                'Usuário')
          : 'Usuário',
      senderRole: sender is Map<String, dynamic>
          ? sender['role']?.toString() ?? 'UNKNOWN'
          : 'UNKNOWN',
      valorOfertado: _parseDouble(
        json['valor_ofertado'] ?? json['valorOfertado'],
      ),
      status: json['status']?.toString() ?? 'EM_ANALISE',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }

    return 0;
  }
}
