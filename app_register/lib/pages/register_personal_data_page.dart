import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../components/text_field_widget.dart';
import '../components/button_widget.dart';
import '../components/searchable_dropdown_widget.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';

class RegisterPersonalDataPage extends StatefulWidget {
  const RegisterPersonalDataPage({super.key});

  @override
  State<RegisterPersonalDataPage> createState() => _RegisterPersonalDataPageState();
}

class _RegisterPersonalDataPageState extends State<RegisterPersonalDataPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _maternalController = TextEditingController();
  final _paternalController = TextEditingController();

  List<LocationData> _countries = [];
  List<LocationData> _birthRegions = [];
  List<LocationData> _birthProvinces = [];
  List<LocationData> _birthDistricts = [];
  List<LocationData> _residenceRegions = [];
  List<LocationData> _residenceProvinces = [];
  List<LocationData> _residenceDistricts = [];

  LocationData? _selectedBirthCountry;
  LocationData? _selectedBirthRegion;
  LocationData? _selectedBirthProvince;
  LocationData? _selectedBirthDistrict;
  LocationData? _selectedResidenceCountry;
  LocationData? _selectedResidenceRegion;
  LocationData? _selectedResidenceProvince;
  LocationData? _selectedResidenceDistrict;

  bool _loadingGeo = true;
  bool _loadingRegions = false;
  bool _loadingProvinces = false;
  bool _loadingDistricts = false;

  late final AnimationController _controller;
  late final Animation<double> _formT;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _formT = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
    _loadInitialData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _middleNameController.dispose();
    _maternalController.dispose();
    _paternalController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final countries = await ApiService.getGeo1();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _loadingGeo = false;
      });
      _restoreFromCache();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingGeo = false);
    }
  }

  void _restoreFromCache() {
    final cache = context.read<AppState>().registerCache;
    _nameController.text = cache.name;
    _middleNameController.text = cache.middleName;
    _maternalController.text = cache.maternalSurname;
    _paternalController.text = cache.paternalSurname;

    if (cache.birthCountryId != null) {
      _selectedBirthCountry = _countries.firstWhere(
        (c) => c.id == cache.birthCountryId,
        orElse: () => _countries.first,
      );
      _loadBirthRegions(_selectedBirthCountry!.id);
    }
    if (cache.residenceCountryId != null) {
      _selectedResidenceCountry = _countries.firstWhere(
        (c) => c.id == cache.residenceCountryId,
        orElse: () => _countries.first,
      );
      _loadResidenceRegions(_selectedResidenceCountry!.id);
    }
  }

  Future<void> _loadBirthRegions(int countryId) async {
    setState(() {
      _loadingRegions = true;
      _birthRegions = [];
      _birthProvinces = [];
      _birthDistricts = [];
      _selectedBirthRegion = null;
      _selectedBirthProvince = null;
      _selectedBirthDistrict = null;
    });
    try {
      final regions = await ApiService.getGeo2(geo1Id: countryId);
      if (!mounted) return;
      setState(() {
        _birthRegions = regions;
        _loadingRegions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRegions = false);
    }
  }

  Future<void> _loadBirthProvinces(int regionId) async {
    setState(() {
      _loadingProvinces = true;
      _birthProvinces = [];
      _birthDistricts = [];
      _selectedBirthProvince = null;
      _selectedBirthDistrict = null;
    });
    try {
      final provinces = await ApiService.getGeo3(geo2Id: regionId);
      if (!mounted) return;
      setState(() {
        _birthProvinces = provinces;
        _loadingProvinces = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadBirthDistricts(int provinceId) async {
    setState(() {
      _loadingDistricts = true;
      _birthDistricts = [];
      _selectedBirthDistrict = null;
    });
    try {
      final districts = await ApiService.getGeo4(geo3Id: provinceId);
      if (!mounted) return;
      setState(() {
        _birthDistricts = districts;
        _loadingDistricts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _loadResidenceRegions(int countryId) async {
    setState(() {
      _residenceRegions = [];
      _residenceProvinces = [];
      _residenceDistricts = [];
      _selectedResidenceRegion = null;
      _selectedResidenceProvince = null;
      _selectedResidenceDistrict = null;
    });
    try {
      final regions = await ApiService.getGeo2(geo1Id: countryId);
      if (!mounted) return;
      setState(() => _residenceRegions = regions);
    } catch (_) {}
  }

  Future<void> _loadResidenceProvinces(int regionId) async {
    setState(() {
      _residenceProvinces = [];
      _residenceDistricts = [];
      _selectedResidenceProvince = null;
      _selectedResidenceDistrict = null;
    });
    try {
      final provinces = await ApiService.getGeo3(geo2Id: regionId);
      if (!mounted) return;
      setState(() => _residenceProvinces = provinces);
    } catch (_) {}
  }

  Future<void> _loadResidenceDistricts(int provinceId) async {
    setState(() {
      _residenceDistricts = [];
      _selectedResidenceDistrict = null;
    });
    try {
      final districts = await ApiService.getGeo4(geo3Id: provinceId);
      if (!mounted) return;
      setState(() => _residenceDistricts = districts);
    } catch (_) {}
  }

  Future<void> _saveAndNext() async {
    if (_nameController.text.trim().isEmpty ||
        _maternalController.text.trim().isEmpty ||
        _paternalController.text.trim().isEmpty) {
      _showError('Complete nombre, apellido materno y paterno');
      return;
    }
    if (_selectedBirthCountry == null || _selectedResidenceCountry == null) {
      _showError('Seleccione país de nacimiento y residencia');
      return;
    }

    final appState = context.read<AppState>();
    final cache = appState.registerCache;
    cache.name = _nameController.text.trim();
    cache.middleName = _middleNameController.text.trim();
    cache.maternalSurname = _maternalController.text.trim();
    cache.paternalSurname = _paternalController.text.trim();

    cache.birthCountryId = _selectedBirthCountry!.id;
    cache.birthCountryName = _selectedBirthCountry!.name;
    cache.birthRegionId = _selectedBirthRegion?.id;
    cache.birthRegionName = _selectedBirthRegion?.name;
    cache.birthProvinceId = _selectedBirthProvince?.id;
    cache.birthProvinceName = _selectedBirthProvince?.name;
    cache.birthDistrictId = _selectedBirthDistrict?.id;
    cache.birthDistrictName = _selectedBirthDistrict?.name;

    cache.residenceCountryId = _selectedResidenceCountry!.id;
    cache.residenceCountryName = _selectedResidenceCountry!.name;
    cache.residenceRegionId = _selectedResidenceRegion?.id;
    cache.residenceRegionName = _selectedResidenceRegion?.name;
    cache.residenceProvinceId = _selectedResidenceProvince?.id;
    cache.residenceProvinceName = _selectedResidenceProvince?.name;
    cache.residenceDistrictId = _selectedResidenceDistrict?.id;
    cache.residenceDistrictName = _selectedResidenceDistrict?.name;

    await appState.saveRegisterCache();
    if (!mounted) return;
    context.go('/register/account');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final theme = AppTheme.of(context);
    const fieldFill = Color(0xFFE4E4E4);

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.secondary,
                foregroundColor: Colors.white,
                elevation: 2,
                expandedHeight: 130,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, right: 20, bottom: 52),
                  title: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Datos Personales',
                      style: theme.titleSmall.copyWith(color: Colors.white),
                    ),
                  ),
                  background: Container(
                    color: theme.secondary,
                    padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Paso 2 de 4',
                            style: theme.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStepIndicator(1),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Opacity(
                  opacity: _formT.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _formT.value)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(theme, 'Información Personal', Icons.person_outline),
                          const SizedBox(height: 16),
                          TextFieldWidget(
                            controller: _nameController,
                            label: 'Nombre *',
                            hint: 'Su nombre',
                            prefixIcon: Icons.person_outline,
                            fillColor: fieldFill,
                          ),
                          const SizedBox(height: 14),
                          TextFieldWidget(
                            controller: _middleNameController,
                            label: 'Segundo Nombre',
                            hint: 'Opcional',
                            prefixIcon: Icons.person_outline,
                            fillColor: fieldFill,
                          ),
                          const SizedBox(height: 14),
                          TextFieldWidget(
                            controller: _paternalController,
                            label: 'Apellido Paterno *',
                            hint: 'Apellido paterno',
                            prefixIcon: Icons.person_outline,
                            fillColor: fieldFill,
                          ),
                          const SizedBox(height: 14),
                          TextFieldWidget(
                            controller: _maternalController,
                            label: 'Apellido Materno *',
                            hint: 'Apellido materno',
                            prefixIcon: Icons.person_outline,
                            fillColor: fieldFill,
                          ),
                          const SizedBox(height: 28),
                          _buildSectionTitle(theme, 'Lugar de Nacimiento', Icons.location_on_outlined),
                          const SizedBox(height: 16),
                          if (_loadingGeo)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            SearchableDropdownWidget(
                              label: 'País',
                              value: _selectedBirthCountry,
                              items: _countries,
                              fillColor: fieldFill,
                              onChanged: (loc) {
                                setState(() => _selectedBirthCountry = loc);
                                if (loc != null) _loadBirthRegions(loc.id);
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_selectedBirthCountry != null) ...[
                              if (_loadingRegions)
                                const Center(child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ))
                              else
                                SearchableDropdownWidget(
                                  label: 'Departamento / Región',
                                  value: _selectedBirthRegion,
                                  items: _birthRegions,
                                  fillColor: fieldFill,
                                  onChanged: (loc) {
                                    setState(() => _selectedBirthRegion = loc);
                                    if (loc != null) _loadBirthProvinces(loc.id);
                                  },
                                ),
                            ],
                            if (_selectedBirthRegion != null) ...[
                              const SizedBox(height: 12),
                              if (_loadingProvinces)
                                const Center(child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ))
                              else
                                SearchableDropdownWidget(
                                  label: 'Provincia',
                                  value: _selectedBirthProvince,
                                  items: _birthProvinces,
                                  fillColor: fieldFill,
                                  onChanged: (loc) {
                                    setState(() => _selectedBirthProvince = loc);
                                    if (loc != null) _loadBirthDistricts(loc.id);
                                  },
                                ),
                            ],
                            if (_selectedBirthProvince != null && _birthDistricts.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              if (_loadingDistricts)
                                const Center(child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ))
                              else
                                SearchableDropdownWidget(
                                  label: 'Distrito',
                                  value: _selectedBirthDistrict,
                                  items: _birthDistricts,
                                  fillColor: fieldFill,
                                  onChanged: (loc) => setState(() => _selectedBirthDistrict = loc),
                                ),
                            ],
                          ],
                          const SizedBox(height: 28),
                          _buildSectionTitle(theme, 'Lugar de Residencia', Icons.home_outlined),
                          const SizedBox(height: 16),
                          if (!_loadingGeo) ...[
                            SearchableDropdownWidget(
                              label: 'País',
                              value: _selectedResidenceCountry,
                              items: _countries,
                              fillColor: fieldFill,
                              onChanged: (loc) {
                                setState(() => _selectedResidenceCountry = loc);
                                if (loc != null) _loadResidenceRegions(loc.id);
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_selectedResidenceCountry != null && _residenceRegions.isNotEmpty)
                              SearchableDropdownWidget(
                                label: 'Departamento / Región',
                                value: _selectedResidenceRegion,
                                items: _residenceRegions,
                                fillColor: fieldFill,
                                onChanged: (loc) {
                                  setState(() => _selectedResidenceRegion = loc);
                                  if (loc != null) _loadResidenceProvinces(loc.id);
                                },
                              ),
                            if (_selectedResidenceRegion != null && _residenceProvinces.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SearchableDropdownWidget(
                                label: 'Provincia',
                                value: _selectedResidenceProvince,
                                items: _residenceProvinces,
                                fillColor: fieldFill,
                                onChanged: (loc) {
                                  setState(() => _selectedResidenceProvince = loc);
                                  if (loc != null) _loadResidenceDistricts(loc.id);
                                },
                              ),
                            ],
                            if (_selectedResidenceProvince != null && _residenceDistricts.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SearchableDropdownWidget(
                                label: 'Distrito',
                                value: _selectedResidenceDistrict,
                                items: _residenceDistricts,
                                fillColor: fieldFill,
                                onChanged: (loc) => setState(() => _selectedResidenceDistrict = loc),
                              ),
                            ],
                          ],
                          const SizedBox(height: 32),
                          ButtonWidget(
                            text: 'Siguiente',
                            icon: Icons.arrow_forward_ios,
                            onPressed: _saveAndNext,
                          ),
                          const SizedBox(height: 16),
                          ButtonWidget(
                            text: 'Atrás',
                            variant: ButtonVariant.outline,
                            icon: Icons.arrow_back_ios,
                            onPressed: () => context.go('/register'),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(AppThemeData theme, String title, IconData icon) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.titleSmall.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: theme.secondary, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Row(
      children: List.generate(4, (i) {
        final isActive = i <= currentStep;
        final isCurrent = i == currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: 4,
            margin: i < 3 ? const EdgeInsets.only(right: 6) : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
              boxShadow: isCurrent
                  ? [BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
