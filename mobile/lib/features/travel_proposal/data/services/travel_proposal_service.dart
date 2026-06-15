import '../../../../core/network/api_client.dart';
import '../../domain/entities/travel_proposal_input.dart';

class TravelProposalService {
  TravelProposalService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<void> createProposal({
    required String token,
    required TravelProposalInput input,
  }) async {
    await _apiClient.postJson(
      '/proposals',
      token: token,
      body: <String, dynamic>{
        'origem': input.origem,
        'destino': input.destino,
        'valor_inicial': input.valorInicial.toStringAsFixed(2),
        'data_ida': input.dataIda.toIso8601String(),
        'data_volta': input.dataVolta?.toIso8601String(),
      },
    );
  }
}