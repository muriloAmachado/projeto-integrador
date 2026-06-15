import '../../../../core/network/api_client.dart';
import '../../domain/entities/travel_proposal_input.dart';
import '../../domain/entities/travel_proposal_summary.dart';

class TravelProposalService {
  TravelProposalService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

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

  Future<List<TravelProposalSummary>> listDriverProposals({
    required String token,
  }) async {
    final response = await _apiClient.getJson(
      '/proposals/driver',
      token: token,
    );

    final items = _extractItems(response);
    return items
        .whereType<Map<String, dynamic>>()
        .map(TravelProposalSummary.fromJson)
        .toList(growable: false);
  }

  Future<List<TravelProposalSummary>> listClientProposals({
    required String token,
  }) async {
    final response = await _apiClient.getJson(
      '/proposals/client',
      token: token,
    );

    final items = _extractItems(response);
    return items
        .whereType<Map<String, dynamic>>()
        .map(TravelProposalSummary.fromJson)
        .toList(growable: false);
  }

  Future<void> createNegotiation({
    required String token,
    required String proposalId,
    required double value,
  }) async {
    await _apiClient.postJson(
      '/negotiations',
      token: token,
      body: <String, dynamic>{
        'propostaId': proposalId,
        'valor_ofertado': value.toStringAsFixed(2),
      },
    );
  }

  Future<void> acceptNegotiation({
    required String token,
    required String negotiationId,
  }) async {
    await _apiClient.patchJson(
      '/negotiations/$negotiationId/accept',
      token: token,
    );
  }

  List<dynamic> _extractItems(dynamic response) {
    if (response is List) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      for (final key in const ['data', 'proposals', 'items', 'result']) {
        final value = response[key];
        if (value is List) {
          return value;
        }
      }
    }

    return const <dynamic>[];
  }
}
