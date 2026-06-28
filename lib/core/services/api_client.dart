import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path')
        .replace(queryParameters: queryParams);
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as List<dynamic>;
      }

      final data = jsonDecode(response.body);
      final detail = data is Map
          ? (data['message'] ?? data['detail'] ?? 'Error desconocido')
          : 'Error desconocido';
      throw ApiException(detail.toString(), statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor.');
    }
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data as Map<String, dynamic>;
      }

      // Spring Boot devuelve {status, message, timestamp}
      final detail = data is Map
          ? (data['message'] ?? data['detail'] ?? 'Error desconocido')
          : 'Error desconocido';
      throw ApiException(detail.toString(), statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor.');
    }
  }
}
