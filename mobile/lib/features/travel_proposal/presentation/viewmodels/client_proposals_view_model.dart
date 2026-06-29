import 'package:flutter/foundation.dart';

import '../../data/repositories/travel_proposal_repository_impl.dart';
import '../../domain/entities/travel_proposal_summary.dart';

class ClientProposalsViewModel extends ChangeNotifier {
  ClientProposalsViewModel({required TravelProposalRepositoryImpl repository})
    : _repository = repository;

  final TravelProposalRepositoryImpl _repository;

  List<TravelProposalSummary> proposals = const [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;

  Future<void> load({required String token}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      proposals = await _repository.listClientProposals(token: token);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendCounterProposal({
    required String token,
    required String proposalId,
    required double value,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.createNegotiation(
        token: token,
        proposalId: proposalId,
        value: value,
      );
      await load(token: token);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> acceptNegotiation({
    required String token,
    required String negotiationId,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.acceptNegotiation(token: token, negotiationId: negotiationId);
      await load(token: token);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> getTripCode({
    required String token,
    required String proposalId,
  }) async {
    try {
      return await _repository.getTripCode(token: token, proposalId: proposalId);
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
      return null;
    }
  }
}
