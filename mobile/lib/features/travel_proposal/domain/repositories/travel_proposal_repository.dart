import '../entities/travel_proposal_input.dart';
import '../entities/travel_proposal_summary.dart';

abstract class TravelProposalRepository {
  Future<void> createProposal({
    required String token,
    required TravelProposalInput input,
  });

  Future<List<TravelProposalSummary>> listDriverProposals({
    required String token,
  });

  Future<List<TravelProposalSummary>> listClientProposals({
    required String token,
  });

  Future<void> createNegotiation({
    required String token,
    required String proposalId,
    required double value,
  });

  Future<void> acceptNegotiation({
    required String token,
    required String negotiationId,
  });

  Future<String> getTripCode({
    required String token,
    required String proposalId,
  });

  Future<List<TravelProposalSummary>> getDriverAcceptedProposals({
    required String token,
  });

  Future<void> finalizeTrip({
    required String token,
    required String code,
  });
}
