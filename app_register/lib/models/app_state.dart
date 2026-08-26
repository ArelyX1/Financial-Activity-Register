import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterCache {
  String identificationNumber = '';
  String idIdentificationType = '';
  String name = '';
  String middleName = '';
  String maternalSurname = '';
  String paternalSurname = '';
  int? birthCountryId;
  String? birthCountryName;
  int? birthRegionId;
  String? birthRegionName;
  int? birthProvinceId;
  String? birthProvinceName;
  int? birthDistrictId;
  String? birthDistrictName;
  int? residenceCountryId;
  String? residenceCountryName;
  int? residenceRegionId;
  String? residenceRegionName;
  int? residenceProvinceId;
  String? residenceProvinceName;
  int? residenceDistrictId;
  String? residenceDistrictName;
  String username = '';
  String email = '';
  String password = '';
  String role = '';

  int? get birthPlaceGadm => birthDistrictId ?? birthProvinceId ?? birthRegionId ?? birthCountryId;
  int? get residencePlaceGadm => residenceDistrictId ?? residenceProvinceId ?? residenceRegionId ?? residenceCountryId;

  Map<String, dynamic> toMap() => {
    'identificationNumber': identificationNumber,
    'idIdentificationType': idIdentificationType,
    'name': name,
    'middleName': middleName,
    'maternalSurname': maternalSurname,
    'paternalSurname': paternalSurname,
    'birthCountryId': birthCountryId,
    'birthCountryName': birthCountryName,
    'birthRegionId': birthRegionId,
    'birthRegionName': birthRegionName,
    'birthProvinceId': birthProvinceId,
    'birthProvinceName': birthProvinceName,
    'birthDistrictId': birthDistrictId,
    'birthDistrictName': birthDistrictName,
    'residenceCountryId': residenceCountryId,
    'residenceCountryName': residenceCountryName,
    'residenceRegionId': residenceRegionId,
    'residenceRegionName': residenceRegionName,
    'residenceProvinceId': residenceProvinceId,
    'residenceProvinceName': residenceProvinceName,
    'residenceDistrictId': residenceDistrictId,
    'residenceDistrictName': residenceDistrictName,
    'username': username,
    'email': email,
    'password': password,
    'role': role,
  };

  void fromMap(Map<String, dynamic> m) {
    identificationNumber = m['identificationNumber'] ?? '';
    idIdentificationType = m['idIdentificationType'] ?? '';
    name = m['name'] ?? '';
    middleName = m['middleName'] ?? '';
    maternalSurname = m['maternalSurname'] ?? '';
    paternalSurname = m['paternalSurname'] ?? '';
    birthCountryId = m['birthCountryId'];
    birthCountryName = m['birthCountryName'];
    birthRegionId = m['birthRegionId'];
    birthRegionName = m['birthRegionName'];
    birthProvinceId = m['birthProvinceId'];
    birthProvinceName = m['birthProvinceName'];
    birthDistrictId = m['birthDistrictId'];
    birthDistrictName = m['birthDistrictName'];
    residenceCountryId = m['residenceCountryId'];
    residenceCountryName = m['residenceCountryName'];
    residenceRegionId = m['residenceRegionId'];
    residenceRegionName = m['residenceRegionName'];
    residenceProvinceId = m['residenceProvinceId'];
    residenceProvinceName = m['residenceProvinceName'];
    residenceDistrictId = m['residenceDistrictId'];
    residenceDistrictName = m['residenceDistrictName'];
    username = m['username'] ?? '';
    email = m['email'] ?? '';
    password = m['password'] ?? '';
    role = m['role'] ?? '';
  }
}

class AppState extends ChangeNotifier {
  String _searchQuery = '';
  bool _pushEnabled = true;
  bool _biometricsEnabled = true;
  bool _darkModeEnabled = false;
  bool _activityNotifications = true;
  bool _newsNotifications = true;
  bool _rememberLogin = false;
  String _lastUsername = '';
  String _accessToken = '';
  String _refreshToken = '';
  String _identificationNumber = '';
  List<String> _roles = const [];
  List<String> _permissions = const [];

  final RegisterCache registerCache = RegisterCache();

  String get searchQuery => _searchQuery;
  bool get pushEnabled => _pushEnabled;
  bool get biometricsEnabled => _biometricsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get activityNotifications => _activityNotifications;
  bool get newsNotifications => _newsNotifications;
  bool get rememberLogin => _rememberLogin;
  String get lastUsername => _lastUsername;
  String get accessToken => _accessToken;
  String get refreshToken => _refreshToken;
  String get identificationNumber => _identificationNumber;
  List<String> get roles => _roles;
  List<String> get permissions => _permissions;
  bool get isLoggedIn => _accessToken.isNotEmpty;

  set searchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  set pushEnabled(bool value) {
    _pushEnabled = value;
    notifyListeners();
  }

  set biometricsEnabled(bool value) {
    _biometricsEnabled = value;
    notifyListeners();
  }

  set darkModeEnabled(bool value) {
    _darkModeEnabled = value;
    notifyListeners();
  }

  set activityNotifications(bool value) {
    _activityNotifications = value;
    notifyListeners();
  }

  set newsNotifications(bool value) {
    _newsNotifications = value;
    notifyListeners();
  }

  set rememberLogin(bool value) {
    _rememberLogin = value;
    notifyListeners();
  }

  set lastUsername(String value) {
    _lastUsername = value;
    notifyListeners();
  }

  void setSession({
    required String accessToken,
    required String refreshToken,
    required List<String> roles,
    required List<String> permissions,
    String identificationNumber = '',
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _roles = roles;
    _permissions = permissions;
    _identificationNumber = identificationNumber;
    _persistSession();
    notifyListeners();
  }

  void logout() {
    _accessToken = '';
    _refreshToken = '';
    _identificationNumber = '';
    _roles = const [];
    _permissions = const [];
    _clearPersistedSession();
    notifyListeners();
  }

  void updateTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _persistSession();
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_accessToken', _accessToken);
    await prefs.setString('session_refreshToken', _refreshToken);
    await prefs.setString('session_identificationNumber', _identificationNumber);
    await prefs.setStringList('session_roles', _roles);
    await prefs.setStringList('session_permissions', _permissions);
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_accessToken');
    await prefs.remove('session_refreshToken');
    await prefs.remove('session_identificationNumber');
    await prefs.remove('session_roles');
    await prefs.remove('session_permissions');
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('session_accessToken') ?? '';
    _refreshToken = prefs.getString('session_refreshToken') ?? '';
    _identificationNumber = prefs.getString('session_identificationNumber') ?? '';
    _roles = prefs.getStringList('session_roles') ?? const [];
    _permissions = prefs.getStringList('session_permissions') ?? const [];
    notifyListeners();
  }

  Future<void> saveRegisterCache() async {
    final prefs = await SharedPreferences.getInstance();
    final map = registerCache.toMap();
    for (final entry in map.entries) {
      if (entry.value == null) {
        await prefs.remove('reg_${entry.key}');
      } else if (entry.value is int) {
        await prefs.setInt('reg_${entry.key}', entry.value as int);
      } else if (entry.value is bool) {
        await prefs.setBool('reg_${entry.key}', entry.value as bool);
      } else {
        await prefs.setString('reg_${entry.key}', entry.value.toString());
      }
    }
  }

  Future<void> loadRegisterCache() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('reg_')) {
        final realKey = key.substring(4);
        final val = prefs.get(key);
        if (val is int) {
          map[realKey] = val;
        } else {
          map[realKey] = val?.toString() ?? '';
        }
      }
    }
    if (map.isNotEmpty) {
      registerCache.fromMap(map);
    }
  }

  Future<void> clearRegisterCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('reg_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    registerCache.identificationNumber = '';
    registerCache.idIdentificationType = '';
    registerCache.name = '';
    registerCache.middleName = '';
    registerCache.maternalSurname = '';
    registerCache.paternalSurname = '';
    registerCache.birthCountryId = null;
    registerCache.birthCountryName = null;
    registerCache.birthRegionId = null;
    registerCache.birthRegionName = null;
    registerCache.birthProvinceId = null;
    registerCache.birthProvinceName = null;
    registerCache.birthDistrictId = null;
    registerCache.birthDistrictName = null;
    registerCache.residenceCountryId = null;
    registerCache.residenceCountryName = null;
    registerCache.residenceRegionId = null;
    registerCache.residenceRegionName = null;
    registerCache.residenceProvinceId = null;
    registerCache.residenceProvinceName = null;
    registerCache.residenceDistrictId = null;
    registerCache.residenceDistrictName = null;
    registerCache.username = '';
    registerCache.email = '';
    registerCache.password = '';
    registerCache.role = '';
  }
}
