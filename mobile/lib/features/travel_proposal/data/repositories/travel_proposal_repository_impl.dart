import '../../domain/entities/travel_proposal_input.dart';
import '../../domain/repositories/travel_proposal_repository.dart';
import '../services/travel_proposal_service.dart';

class TravelProposalRepositoryImpl implements TravelProposalRepository {
  TravelProposalRepositoryImpl({required TravelProposalService service}) : _service = service;

  final TravelProposalService _service;

  @override
  Future<void> createProposal({
    required String token,
    required TravelProposalInput input,
  }) {
    return _service.createProposal(token: token, input: input);
  }
}