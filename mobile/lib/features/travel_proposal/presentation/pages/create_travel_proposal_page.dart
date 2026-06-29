import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../data/repositories/travel_proposal_repository_impl.dart';
import '../../data/services/travel_proposal_service.dart';
import '../../domain/entities/travel_proposal_input.dart';
import '../../domain/usecases/create_travel_proposal_usecase.dart';
import '../viewmodels/create_travel_proposal_view_model.dart';

class CreateTravelProposalPage extends StatefulWidget {
  const CreateTravelProposalPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<CreateTravelProposalPage> createState() => _CreateTravelProposalPageState();
}

class _CreateTravelProposalPageState extends State<CreateTravelProposalPage> {
  final _formKey = GlobalKey<FormState>();
  final _origemController = TextEditingController();
  final _destinoController = TextEditingController();
  final _valorController = TextEditingController();
  DateTime? _dataIda;
  DateTime? _dataVolta;

  late final CreateTravelProposalViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CreateTravelProposalViewModel(
      useCase: CreateTravelProposalUseCase(
        TravelProposalRepositoryImpl(
          service: TravelProposalService(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _origemController.dispose();
    _destinoController.dispose();
    _valorController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickDataIda() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dataIda ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (selectedDate != null) {
      setState(() => _dataIda = selectedDate);
    }
  }

  Future<void> _pickDataVolta() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dataVolta ?? _dataIda ?? DateTime.now().add(const Duration(days: 2)),
      firstDate: _dataIda ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (selectedDate != null) {
      setState(() => _dataVolta = selectedDate);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _dataIda == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios e selecione a data de ida.')),
      );
      return;
    }

    if (_dataVolta != null && _dataVolta!.isBefore(_dataIda!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A data de volta deve ser posterior à data de ida.')),
      );
      return;
    }

    final valor = double.tryParse(_valorController.text.replaceAll(',', '.'));
    if (valor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido.')),
      );
      return;
    }

    await _viewModel.createProposal(
      token: widget.session.token,
      input: TravelProposalInput(
        origem: _origemController.text.trim(),
        destino: _destinoController.text.trim(),
        valorInicial: valor,
        dataIda: _dataIda!,
        dataVolta: _dataVolta,
      ),
    );

    if (!mounted) return;

    if (_viewModel.proposalCreated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demanda criada com sucesso.')),
      );
      Navigator.of(context).pop(true);
      return;
    }

    if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nova Demanda de Viagem'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                context.read<AuthViewModel>().logout();
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Consumer<CreateTravelProposalViewModel>(
              builder: (context, viewModel, _) {
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Crie uma nova demanda',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Informe origem, destino, valor inicial e datas da viagem.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _origemController,
                        decoration: const InputDecoration(
                          labelText: 'Origem',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a origem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _destinoController,
                        decoration: const InputDecoration(
                          labelText: 'Destino',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o destino';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _valorController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Valor inicial',
                          prefixIcon: Icon(Icons.attach_money_outlined),
                          hintText: 'Ex.: 250.00',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o valor inicial';
                          }
                          if (double.tryParse(value.replaceAll(',', '.')) == null) {
                            return 'Informe um valor válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _pickDataIda,
                        child: Text(
                          _dataIda == null
                              ? 'Selecionar data de ida'
                              : 'Data de ida: ${_dataIda!.day.toString().padLeft(2, '0')}/${_dataIda!.month.toString().padLeft(2, '0')}/${_dataIda!.year}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _pickDataVolta,
                        child: Text(
                          _dataVolta == null
                              ? 'Selecionar data de volta opcional'
                              : 'Data de volta: ${_dataVolta!.day.toString().padLeft(2, '0')}/${_dataVolta!.month.toString().padLeft(2, '0')}/${_dataVolta!.year}',
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (viewModel.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            viewModel.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      FilledButton(
                        onPressed: viewModel.isLoading ? null : _submit,
                        child: viewModel.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Criar demanda'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}