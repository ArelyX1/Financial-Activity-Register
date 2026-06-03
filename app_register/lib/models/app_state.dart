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

  String get searchQuery => _searchQuery;
  bool get pushEnabled => _pushEnabled;
  bool get biometricsEnabled => _biometricsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get activityNotifications => _activityNotifications;
  bool get newsNotifications => _newsNotifications;
  bool get rememberLogin => _rememberLogin;
  String get lastUsername => _lastUsername;

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
}
