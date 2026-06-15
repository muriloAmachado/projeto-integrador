import 'package:flutter/foundation.dart';

import '../../domain/entities/travel_proposal_input.dart';
import '../../domain/usecases/create_travel_proposal_usecase.dart';

class CreateTravelProposalViewModel extends ChangeNotifier {
  CreateTravelProposalViewModel({required CreateTravelProposalUseCase useCase})
      : _useCase = useCase;

  final CreateTravelProposalUseCase _useCase;

  bool isLoading = false;
  String? errorMessage;
  bool proposalCreated = false;

  Future<void> createProposal({
    required String token,
    required TravelProposalInput input,
  }) async {
    isLoading = true;
    errorMessage = null;
    proposalCreated = false;
    notifyListeners();

    try {
      await _useCase(token: token, input: input);
      proposalCreated = true;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}