class CompletedTripSummary {
  CompletedTripSummary({
    required this.id,
    required this.propostaId,
    required this.origem,
    required this.destino,
    required this.dataIda,
    this.dataVolta,
    required this.valorFinal,
    required this.codigoConfirma,
    required this.finalizada,
    required this.realizadaEm,
    required this.clienteNome,
  });

  final String id;
  final String propostaId;
  final String origem;
  final String destino;
  final DateTime dataIda;
  final DateTime? dataVolta;
  final double valorFinal;
  final String codigoConfirma;
  final bool finalizada;
  final DateTime realizadaEm;
  final String clienteNome;

  factory CompletedTripSummary.fromJson(Map<String, dynamic> json) {
    final proposta = json['proposta'] as Map<String, dynamic>? ?? {};
    final cliente = json['cliente'] as Map<String, dynamic>? ?? {};

    return CompletedTripSummary(
      id: json['id']?.toString() ?? '',
      propostaId: json['propostaId']?.toString() ?? '',
      origem: proposta['origem']?.toString() ?? '',
      destino: proposta['destino']?.toString() ?? '',
      dataIda: _parseDate(proposta['data_ida']) ?? DateTime.now(),
      dataVolta: _parseDate(proposta['data_volta']),
      valorFinal: _parseDouble(json['valor_final']),
      codigoConfirma: json['codigo_confirma']?.toString() ?? '',
      finalizada: json['finalizada'] == true,
      realizadaEm: _parseDate(json['realizada_em']) ?? DateTime.now(),
      clienteNome: cliente['nome']?.toString() ??
          cliente['email']?.toString() ??
          'Cliente',
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 0;
  }
}
