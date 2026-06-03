import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../components/form_section_widget.dart';
import '../components/form_section2_widget.dart';
import '../components/form_section3_widget.dart';
import '../components/form_section4_widget.dart';
import '../components/turn_selector_widget.dart';
import '../components/button_widget.dart';

class ActivityRegistrationFormPage extends StatefulWidget {
  const ActivityRegistrationFormPage({super.key});

  @override
  State<ActivityRegistrationFormPage> createState() => _ActivityRegistrationFormPageState();
}

class _ActivityRegistrationFormPageState extends State<ActivityRegistrationFormPage> {
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  String? _clientType;
  String? _disbursementMethod;
  String? _bank;
  String? _status;
  TurnOption _turn = TurnOption.morning;
  bool _hasGuarantor = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _obsCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      _dateCtrl.text = '${date.day}/${date.month}/${date.year}';
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nueva Actividad', style: theme.headlineSmall.copyWith(color: theme.primaryText)),
            const SizedBox(height: 4),
            Text('Complete los datos para registrar una nueva gestión', style: theme.bodyMedium.copyWith(color: theme.secondaryText)),
            const SizedBox(height: 20),

            const Text('Turno', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TurnSelectorWidget(value: _turn, onChanged: (v) => setState(() => _turn = v)),
            const SizedBox(height: 20),

            FormSectionWidget(
              nameController: _nameCtrl,
              idController: _idCtrl,
              phoneController: _phoneCtrl,
              emailController: _emailCtrl,
              selectedClientType: _clientType,
              onClientTypeChanged: (v) => setState(() => _clientType = v),
            ),
            const SizedBox(height: 16),

            FormSection2Widget(
              amountController: _amountCtrl,
              dateController: _dateCtrl,
              selectedMethod: _disbursementMethod,
              selectedBank: _bank,
              onMethodChanged: (v) => setState(() => _disbursementMethod = v),
              onBankChanged: (v) => setState(() => _bank = v),
              onSelectDate: _pickDate,
            ),
            const SizedBox(height: 16),

            FormSection3Widget(
              plateController: _plateCtrl,
              brandController: _brandCtrl,
              modelController: _modelCtrl,
              yearController: _yearCtrl,
              colorController: _colorCtrl,
            ),
            const SizedBox(height: 16),

            FormSection4Widget(
              observationsController: _obsCtrl,
              referenceController: _refCtrl,
              selectedStatus: _status,
              onStatusChanged: (v) => setState(() => _status = v),
              hasGuarantor: _hasGuarantor,
              onGuarantorChanged: (v) => setState(() => _hasGuarantor = v),
            ),
            const SizedBox(height: 24),

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
}
