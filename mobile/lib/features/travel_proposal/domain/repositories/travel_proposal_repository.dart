import '../entities/travel_proposal_input.dart';

abstract class TravelProposalRepository {
  Future<void> createProposal({
    required String token,
    required TravelProposalInput input,
  });
}