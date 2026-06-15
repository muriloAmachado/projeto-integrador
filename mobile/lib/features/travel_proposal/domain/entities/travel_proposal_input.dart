class TravelProposalInput {
  TravelProposalInput({
    required this.origem,
    required this.destino,
    required this.valorInicial,
    required this.dataIda,
    this.dataVolta,
  });

  final String origem;
  final String destino;
  final double valorInicial;
  final DateTime dataIda;
  final DateTime? dataVolta;
}