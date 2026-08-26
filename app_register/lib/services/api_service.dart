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

class PersonData {
  final String? id;
  final String? name;
  final String? middleName;
  final String? maternalSurname;
  final String? paternalSurname;
  final int idIdentificationType;
  final String identificationNumber;
  final int? birthPlaceGadm;
  final int? residencePlaceGadm;
  final String? role;
  final String? username;
  final String? email;
  final List<String> roleCategories;

  const PersonData({
    this.id,
    this.name,
    this.middleName,
    this.maternalSurname,
    this.paternalSurname,
    required this.idIdentificationType,
    required this.identificationNumber,
    this.birthPlaceGadm,
    this.residencePlaceGadm,
    this.role,
    this.username,
    this.email,
    this.roleCategories = const [],
  });

  factory PersonData.fromJson(Map<String, dynamic> json) {
    return PersonData(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      middleName: json['middle_name']?.toString(),
      maternalSurname: json['maternal_surname']?.toString(),
      paternalSurname: json['paternal_surname']?.toString(),
      idIdentificationType: json['id_identification_type'] as int? ?? 0,
      identificationNumber: json['identification_number']?.toString() ?? '',
      birthPlaceGadm: json['birth_place_gadm'] as int?,
      residencePlaceGadm: json['residence_place_gadm'] as int?,
      role: json['role']?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
    );
  }

  bool get isRegistered => name != null && name!.isNotEmpty;
}

class LocationData {
  final int id;
  final String code;
  final String name;

  const LocationData({required this.id, required this.code, required this.name});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      id: json['id'] as int,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class IdTypeData {
  final int id;
  final String countryIso;
  final String? code;
  final String name;
  final int minLength;
  final int maxLength;
  final bool? isNumeric;
  final bool? isActive;

  const IdTypeData({
    required this.id,
    required this.countryIso,
    this.code,
    required this.name,
    required this.minLength,
    required this.maxLength,
    this.isNumeric,
    this.isActive,
  });

  factory IdTypeData.fromJson(Map<String, dynamic> json) {
    return IdTypeData(
      id: json['id'] as int,
      countryIso: json['country_iso']?.toString() ?? 'PE',
      code: json['code']?.toString(),
      name: json['name']?.toString() ?? '',
      minLength: json['min_length'] as int? ?? 1,
      maxLength: json['max_length'] as int? ?? 0,
      isNumeric: json['is_numeric'] as bool?,
      isActive: json['is_active'] as bool?,
    );
  }
}

class ApiService {
  static Future<Map<String, dynamic>> _post(String query, [Map<String, dynamic>? variables]) async {
    final response = await http.post(
      Uri.parse(ApiConfig.apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        if (variables != null) 'variables': variables,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['errors'] != null) {
      throw ApiException(response.statusCode, _extractError(body));
    }
    return body['data'] as Map<String, dynamic>;
  }

  static Future<List<IdTypeData>> getIdentificationTypes({required String token}) async {
    final query = '''
      query GetIdentificationTypes(\$token: String!) {
        identification_types(token: \$token) {
          id
          country_iso
          code
          name
          min_length
          max_length
          is_numeric
          is_active
        }
      }
    ''';
    final data = await _post(query, {'token': token});
    final list = data['identification_types'] as List<dynamic>? ?? [];
    return list.map((e) => IdTypeData.fromJson(e as Map<String, dynamic>)).toList();
  }

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

    final data = await _post(query, {
      'identificationNumber': identificationNumber,
      'password': password,
    });

    final loginData = data['login'] as Map<String, dynamic>?;
    final success = loginData?['success'] == true;
    final roles = (loginData?['roles'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final permissions = ((loginData?['permissions'] as List<dynamic>? ?? [])
            .map((e) => (e as Map<String, dynamic>)['code']?.toString() ?? ''))
        .where((e) => e.isNotEmpty)
        .toList();

    return LoginResult(
      success: success,
      accessToken: loginData?['access_token'] as String?,
      refreshToken: loginData?['refresh_token'] as String?,
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
    final data = await _post(query, {'token': token});
    return data['go_mobil_app'] == true;
  }

  static Future<PersonData?> getPerson({required String identificationNumber}) async {
    final query = '''
      query GetPerson(\$identificationNumber: String!) {
        person(identification_number: \$identificationNumber) {
          id
          name
          middle_name
          maternal_surname
          paternal_surname
          id_identification_type
          identification_number
          birth_place_gadm
          residence_place_gadm
          role
          username
          email
        }
      }
    ''';
    final data = await _post(query, {'identificationNumber': identificationNumber});
    final personJson = data['person'] as Map<String, dynamic>?;
    if (personJson == null) return null;
    return PersonData.fromJson(personJson);
  }

  static Future<List<LocationData>> getGeo1() async {
    final query = '''
      query { geo1 { id code name } }
    ''';
    final data = await _post(query);
    final list = data['geo1'] as List<dynamic>? ?? [];
    return list.map((e) => LocationData.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<LocationData>> getGeo2({required int geo1Id}) async {
    final query = '''
      query GetGeo2(\$geo1Id: Int!) {
        geo2(geo1_id: \$geo1Id) { id code name }
      }
    ''';
    final data = await _post(query, {'geo1Id': geo1Id});
    final list = data['geo2'] as List<dynamic>? ?? [];
    return list.map((e) => LocationData.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<LocationData>> getGeo3({required int geo2Id}) async {
    final query = '''
      query GetGeo3(\$geo2Id: Int!) {
        geo3(geo2_id: \$geo2Id) { id code name }
      }
    ''';
    final data = await _post(query, {'geo2Id': geo2Id});
    final list = data['geo3'] as List<dynamic>? ?? [];
    return list.map((e) => LocationData.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<LocationData>> getGeo4({required int geo3Id}) async {
    final query = '''
      query GetGeo4(\$geo3Id: Int!) {
        geo4(geo3_id: \$geo3Id) { id code name }
      }
    ''';
    final data = await _post(query, {'geo3Id': geo3Id});
    final list = data['geo4'] as List<dynamic>? ?? [];
    return list.map((e) => LocationData.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<PersonData>> searchPersons({
    required String token,
    required String search,
  }) async {
    final query = '''
      query SearchPersons(\$search: String!, \$token: String!) {
        search_persons(search: \$search, token: \$token) {
          id
          name
          paternal_surname
          maternal_surname
          identification_number
          id_identification_type
          email
          username
          role_categories
        }
      }
    ''';
    final data = await _post(query, {
      'search': search,
      'token': token,
    });
    final list = data['search_persons'] as List<dynamic>? ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return PersonData(
        id: m['id']?.toString(),
        name: m['name']?.toString(),
        paternalSurname: m['paternal_surname']?.toString(),
        maternalSurname: m['maternal_surname']?.toString(),
        identificationNumber: m['identification_number']?.toString() ?? '',
        idIdentificationType: m['id_identification_type'] as int? ?? 0,
        email: m['email']?.toString(),
        username: m['username']?.toString(),
        roleCategories: (m['role_categories'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
    }).toList();
  }

  static Future<bool> createPerson({
    required int idIdentificationType,
    required String identificationNumber,
    required List<String> roleNames,
  }) async {
    final query = '''
      mutation CreatePerson(\$input: CreatePersonInput!) {
        create_person(input: \$input) {
          id
          identification_number
        }
      }
    ''';
    await _post(query, {
      'input': {
        'id_identification_type': idIdentificationType,
        'identification_number': identificationNumber,
        'role_names': roleNames,
      },
    });
    return true;
  }

  static Future<bool> registerPerson({
    required String identificationNumber,
    required String name,
    String? middleName,
    required String maternalSurname,
    required String paternalSurname,
    required int birthPlaceGadm,
    required int residencePlaceGadm,
  }) async {
    final query = '''
      mutation Register(\$input: RegisterInput!) {
        register(input: \$input) {
          id
          identification_number
        }
      }
    ''';
    await _post(query, {
      'input': {
        'identification_number': identificationNumber,
        'name': name,
        'middle_name': middleName,
        'maternal_surname': maternalSurname,
        'paternal_surname': paternalSurname,
        'birth_place_gadm': birthPlaceGadm,
        'residence_place_gadm': residencePlaceGadm,
      },
    });
    return true;
  }

  static Future<bool> createUser({
    required String identificationNumber,
    required String username,
    required String email,
    required String password,
    required int nIdAccountProvider,
    String providerId = '',
  }) async {
    final query = '''
      mutation CreateUser(\$input: CreateUserInput!) {
        create_user(input: \$input) {
          id
          username
          email
        }
      }
    ''';
    await _post(query, {
      'input': {
        'identification_number': identificationNumber,
        'username': username,
        'email': email,
        'password': password,
        'n_id_account_provider': nIdAccountProvider,
        'provider_id': providerId,
      },
    });
    return true;
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
