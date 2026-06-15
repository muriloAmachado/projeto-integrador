import '../entities/travel_proposal_summary.dart';
import '../repositories/travel_proposal_repository.dart';

class ListDriverProposalsUseCase {
  ListDriverProposalsUseCase(this._repository);

  final TravelProposalRepository _repository;

  Future<List<TravelProposalSummary>> call({required String token}) {
    return _repository.listDriverProposals(token: token);
  }
}
