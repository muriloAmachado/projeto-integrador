import '../../domain/entities/travel_proposal_input.dart';
import '../../domain/entities/travel_proposal_summary.dart';
import '../../domain/repositories/travel_proposal_repository.dart';
import '../services/travel_proposal_service.dart';

class TravelProposalRepositoryImpl implements TravelProposalRepository {
  TravelProposalRepositoryImpl({required TravelProposalService service})
    : _service = service;

  final TravelProposalService _service;

  @override
  Future<void> createProposal({
    required String token,
    required TravelProposalInput input,
  }) {
    return _service.createProposal(token: token, input: input);
  }

  @override
  Future<List<TravelProposalSummary>> listDriverProposals({
    required String token,
  }) {
    return _service.listDriverProposals(token: token);
  }

  @override
  Future<List<TravelProposalSummary>> listClientProposals({
    required String token,
  }) {
    return _service.listClientProposals(token: token);
  }

  @override
  Future<void> createNegotiation({
    required String token,
    required String proposalId,
    required double value,
  }) {
    return _service.createNegotiation(
      token: token,
      proposalId: proposalId,
      value: value,
    );
  }

  @override
  Future<void> acceptNegotiation({
    required String token,
    required String negotiationId,
  }) {
    return _service.acceptNegotiation(token: token, negotiationId: negotiationId);
  }

  @override
  Future<String> getTripCode({required String token, required String proposalId}) {
    return _service.getTripCode(token: token, proposalId: proposalId);
  }

  @override
  Future<List<TravelProposalSummary>> getDriverAcceptedProposals({required String token}) {
    return _service.getDriverAcceptedProposals(token: token);
  }

  @override
  Future<void> finalizeTrip({required String token, required String code}) {
    return _service.finalizeTrip(token: token, code: code);
  }
}
