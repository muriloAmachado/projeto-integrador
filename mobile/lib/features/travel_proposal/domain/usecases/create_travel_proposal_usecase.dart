import '../entities/travel_proposal_input.dart';
import '../repositories/travel_proposal_repository.dart';

class CreateTravelProposalUseCase {
  CreateTravelProposalUseCase(this._repository);

  final TravelProposalRepository _repository;

  Future<void> call({
    required String token,
    required TravelProposalInput input,
  }) {
    return _repository.createProposal(token: token, input: input);
  }
}