import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../components/text_field_widget.dart';
import '../components/button_widget.dart';
import '../components/turn_selector_widget.dart';
import '../components/date_picker_widget.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';

class ActivityRegistrationFormPage extends StatefulWidget {
  const ActivityRegistrationFormPage({super.key});

  @override
  State<ActivityRegistrationFormPage> createState() => _ActivityRegistrationFormPageState();
}

class _ActivityRegistrationFormPageState extends State<ActivityRegistrationFormPage> {
  final _docNumberController = TextEditingController();
  final _docTypeController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _paternalController = TextEditingController();
  final _maternalController = TextEditingController();
  final _amountController = TextEditingController();
  final _moraController = TextEditingController();
  final _dateController = TextEditingController();
  final _dealershipController = TextEditingController();

  bool _loading = true;
  bool _isVehicular = false;
  TurnOption _turn = TurnOption.morning;
  List<IdTypeData> _idTypes = [];
  IdTypeData? _selectedIdType;
  List<PersonData> _searchResults = [];
  bool _searching = false;
  PersonData? _selectedPerson;

  @override
  void initState() {
    super.initState();
    _setDefaultDateTime();
    _loadUserRole();
  }

  @override
  void dispose() {
    _docNumberController.dispose();
    _docTypeController.dispose();
    _firstNameController.dispose();
    _secondNameController.dispose();
    _paternalController.dispose();
    _maternalController.dispose();
    _amountController.dispose();
    _moraController.dispose();
    _dateController.dispose();
    _dealershipController.dispose();
    super.dispose();
  }

  DateTime _selectedDateTime = DateTime.now();

  void _setDefaultDateTime() {
    final now = DateTime.now();
    final peruOffset = const Duration(hours: -5);
    final peruTime = now.toUtc().add(peruOffset);
    _selectedDateTime = DateTime(
      peruTime.year, peruTime.month, peruTime.day,
      peruTime.hour, peruTime.minute,
    );
    _dateController.text = DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime);
  }

  Future<void> _loadUserRole() async {
    final appState = context.read<AppState>();

    if (appState.roles.any((r) => r.toLowerCase().contains('vehicular'))) {
      _isVehicular = true;
    }

    final idNumber = appState.identificationNumber;
    if (idNumber.isNotEmpty) {
      try {
        final person = await ApiService.getPerson(identificationNumber: idNumber);
        if (person?.role != null) {
          _isVehicular = person!.role!.toLowerCase().contains('vehicular');
        }
      } catch (_) {}
    }

    if (appState.accessToken.isNotEmpty) {
      try {
        _idTypes = await ApiService.getIdentificationTypes(token: appState.accessToken);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _searchPersons(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    final token = context.read<AppState>().accessToken;
    if (token.isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await ApiService.searchPersonsByRole(
        token: token,
        roleNames: ['client'],
        search: query,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  void _selectPerson(PersonData person) {
    setState(() {
      _selectedPerson = person;
      _docNumberController.text = person.identificationNumber;
      _firstNameController.text = person.name ?? '';
      _paternalController.text = person.paternalSurname ?? '';
      _maternalController.text = person.maternalSurname ?? '';
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: Text('Registro de Actividad', style: theme.titleLarge.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/activity/history'),
        ),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Cargando datos...', style: theme.bodyMedium.copyWith(color: theme.secondaryText)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nueva Actividad', style: theme.headlineSmall.copyWith(color: theme.primaryText)),
                  const SizedBox(height: 4),
                  Text(
                    'Complete los datos para registrar una nueva gestión',
                    style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                  ),
                  const SizedBox(height: 20),

                  if (_isVehicular) ...[
                    _buildSectionHeader(theme, 'Turno', Icons.access_time),
                    const SizedBox(height: 8),
                    TurnSelectorWidget(value: _turn, onChanged: (v) => setState(() => _turn = v)),
                    const SizedBox(height: 20),
                  ],

                  _buildClientSection(theme),
                  const SizedBox(height: 16),

                  _buildDisbursementSection(theme),
                  const SizedBox(height: 16),

                  if (_isVehicular) ...[
                    _buildDealershipSection(theme),
                    const SizedBox(height: 16),
                  ],

                  ButtonWidget(
                    text: 'Registrar Actividad',
                    icon: Icons.save,
                    onPressed: () => context.go('/dashboard'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(AppThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.secondary, size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.titleSmall.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildClientSection(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Datos del Cliente', Icons.person_outline),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              TextFieldWidget(
                controller: _docNumberController,
                label: 'Número de Documento',
                hint: 'Ingrese número de documento',
                prefixIcon: Icons.credit_card,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  _selectedPerson = null;
                  _searchPersons(v);
                },
              ),
              if (_searching)
                Positioned(
                  right: 12, top: 14,
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.secondary)),
                ),
              if (_searchResults.isNotEmpty && !_searching)
                Positioned(
                  top: 58, left: 0, right: 0,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE1E1E1)),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (_, i) {
                          final p = _searchResults[i];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.secondary.withValues(alpha: 0.1),
                              child: Icon(Icons.person, size: 16, color: theme.secondary),
                            ),
                            title: Text(
                              p.identificationNumber,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.primaryText),
                            ),
                            subtitle: Text(
                              [p.name, p.paternalSurname].where((e) => e != null && e.isNotEmpty).join(' '),
                              style: TextStyle(fontSize: 12, color: theme.secondaryText),
                            ),
                            onTap: () => _selectPerson(p),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showIdTypePicker,
            child: AbsorbPointer(
              child: TextFieldWidget(
                controller: _docTypeController,
                label: 'Tipo de Documento',
                hint: _idTypes.isEmpty ? 'Cargando...' : 'Seleccionar tipo',
                prefixIcon: Icons.badge_outlined,
                suffixIcon: Icons.arrow_drop_down,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFieldWidget(
            controller: _firstNameController,
            label: 'Primer Nombre',
            hint: 'Ingrese primer nombre',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          TextFieldWidget(
            controller: _secondNameController,
            label: 'Segundo Nombre',
            hint: 'Opcional',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          TextFieldWidget(
            controller: _paternalController,
            label: 'Apellido Paterno',
            hint: 'Ingrese apellido paterno',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          TextFieldWidget(
            controller: _maternalController,
            label: 'Apellido Materno',
            hint: 'Ingrese apellido materno',
            prefixIcon: Icons.person_outline,
          ),
        ],
      ),
    );
  }

  void _showIdTypePicker() {
    final theme = AppTheme.of(context);
    final activeTypes = _idTypes.where((t) => t.isActive != false).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final searchController = TextEditingController();
        List<IdTypeData> filtered = List.from(activeTypes);
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryText.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Buscar tipo de documento...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.secondary),
                        ),
                      ),
                      onChanged: (v) {
                        final q = v.toLowerCase();
                        setModalState(() {
                          filtered = activeTypes.where((t) =>
                            t.name.toLowerCase().contains(q) ||
                            (t.code?.toLowerCase().contains(q) ?? false)
                          ).toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final t = filtered[i];
                        final isSelected = _selectedIdType?.id == t.id;
                        return ListTile(
                          leading: Icon(
                            Icons.badge_outlined,
                            color: isSelected ? theme.secondary : theme.secondaryText,
                          ),
                          title: Text(
                            '${t.name} (${t.countryIso})',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? theme.secondary : theme.primaryText,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: theme.secondary)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedIdType = t;
                              _docTypeController.text = t.name;
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDisbursementSection(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Desembolso', Icons.attach_money),
          const SizedBox(height: 16),
          TextFieldWidget(
            controller: _amountController,
            label: 'Monto',
            hint: 'Ingrese monto',
            prefixIcon: Icons.monetization_on_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFieldWidget(
            controller: _moraController,
            label: 'Mora',
            hint: 'Opcional',
            prefixIcon: Icons.percent,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              showDateTimePickerSheet(
                context: context,
                initialDateTime: _selectedDateTime,
                onConfirmed: (dateTime) {
                  setState(() {
                    _selectedDateTime = dateTime;
                    _dateController.text = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
                  });
                },
              );
            },
            child: AbsorbPointer(
              child: TextFieldWidget(
                controller: _dateController,
                label: 'Fecha y Hora',
                hint: 'Fecha y hora del desembolso',
                prefixIcon: Icons.calendar_today,
                suffixIcon: Icons.arrow_drop_down,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealershipSection(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'Concesionaria', Icons.store_outlined),
          const SizedBox(height: 16),
          TextFieldWidget(
            controller: _dealershipController,
            label: 'Nombre de la Concesionaria',
            hint: 'Ingrese nombre de la concesionaria',
            prefixIcon: Icons.storefront_outlined,
          ),
        ],
      ),
    );
  }
}
