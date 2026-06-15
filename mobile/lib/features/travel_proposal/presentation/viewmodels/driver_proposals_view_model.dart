import 'package:flutter/foundation.dart';

import '../../domain/entities/travel_proposal_summary.dart';
import '../../domain/usecases/list_driver_proposals_usecase.dart';

class DriverProposalsViewModel extends ChangeNotifier {
  DriverProposalsViewModel({required ListDriverProposalsUseCase useCase})
    : _useCase = useCase;

  final ListDriverProposalsUseCase _useCase;

  List<TravelProposalSummary> proposals = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load({required String token}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      proposals = await _useCase(token: token);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
