import 'package:flutter/material.dart';

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
  List<String> _roles = const [];
  List<String> _permissions = const [];

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
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _roles = roles;
    _permissions = permissions;
    notifyListeners();
  }

  void logout() {
    _accessToken = '';
    _refreshToken = '';
    _roles = const [];
    _permissions = const [];
    notifyListeners();
  }
}
