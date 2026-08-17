import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static String get apiUrl {
    final url = dotenv.env['API_URL'] ?? '';
    if (url.isEmpty) {
      throw StateError('API_URL not configured in .env');
    }
    return url;
  }
}

class LoginResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final List<String> roles;
  final List<String> permissions;

  const LoginResult({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.roles = const [],
    this.permissions = const [],
  });
}

class ApiService {
  static Future<LoginResult> login({
    required String identificationNumber,
    required String password,
  }) async {
    final query = '''
      mutation Login(\$identificationNumber: String!, \$password: String!) {
        login(identification_number: \$identificationNumber, password: \$password) {
          success
          access_token
          refresh_token
          roles
          permissions {
            code
          }
        }
      }
    ''';

    final response = await http.post(
      Uri.parse(ApiConfig.apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'variables': {
          'identificationNumber': identificationNumber,
          'password': password,
        },
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['errors'] != null) {
      throw ApiException(
        response.statusCode,
        _extractError(body),
      );
    }

    final data = body['data']?['login'] as Map<String, dynamic>?;
    final success = data?['success'] == true;
    final roles = (data?['roles'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final permissions = ((data?['permissions'] as List<dynamic>? ?? [])
            .map((e) => (e as Map<String, dynamic>)['code']?.toString() ?? ''))
        .where((e) => e.isNotEmpty)
        .toList();

    return LoginResult(
      success: success,
      accessToken: data?['access_token'] as String?,
      refreshToken: data?['refresh_token'] as String?,
      roles: roles,
      permissions: permissions,
    );
  }

  static Future<bool> canAccessMobile({required String token}) async {
    final query = '''
      query CanAccessMobile(\$token: String!) {
        go_mobil_app(token: \$token)
      }
    ''';

    final response = await http.post(
      Uri.parse(ApiConfig.apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'variables': {'token': token},
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['errors'] != null) {
      throw ApiException(
        response.statusCode,
        _extractError(body),
      );
    }
    return body['data']?['go_mobil_app'] == true;
  }

  static String _extractError(Map<String, dynamic> body) {
    final errors = body['errors'] as List<dynamic>? ?? [];
    if (errors.isNotEmpty) {
      return (errors.first as Map<String, dynamic>)['message']?.toString() ??
          'Unknown error';
    }
    return 'Unknown error';
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
