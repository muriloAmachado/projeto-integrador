import 'package:flutter/foundation.dart';

import '../../data/repositories/travel_proposal_repository_impl.dart';
import '../../domain/entities/travel_proposal_summary.dart';

class DriverProposalsViewModel extends ChangeNotifier {
  DriverProposalsViewModel({required TravelProposalRepositoryImpl repository})
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
      proposals = await _repository.listDriverProposals(token: token);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Motorista envia uma oferta/contraproposta para a demanda do grupo.
  Future<void> sendOffer({
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

  /// Motorista aceita a contraproposta enviada pelo cliente, fechando a viagem.
  Future<void> acceptNegotiation({
    required String token,
    required String negotiationId,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.acceptNegotiation(
        token: token,
        negotiationId: negotiationId,
      );
      await load(token: token);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
