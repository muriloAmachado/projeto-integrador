import 'package:flutter/foundation.dart';

import '../../data/repositories/travel_proposal_repository_impl.dart';
import '../../domain/entities/travel_proposal_summary.dart';

class DriverTripsViewModel extends ChangeNotifier {
  DriverTripsViewModel({required TravelProposalRepositoryImpl repository})
      : _repository = repository;

  final TravelProposalRepositoryImpl _repository;

  List<TravelProposalSummary> trips = const [];
  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;

  Future<void> load({required String token}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      trips = await _repository.getDriverAcceptedProposals(token: token);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> finalizeTrip({required String token, required String code}) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.finalizeTrip(token: token, code: code);
      await load(token: token);
      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
