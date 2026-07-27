import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
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

  /// Cliente HTTP con manejo de SSL.
  /// En debug: acepta certificados para facilitar desarrollo.
  /// En release: usa el cliente estándar con validación estricta.
  static http.Client _buildClient() {
    if (kDebugMode) {
      final ioClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      return IOClient(ioClient);
    }
    return http.Client();
  }

  static String _debugError(Object e) =>
      kDebugMode ? 'No se pudo conectar con el servidor. ($e)' : 'No se pudo conectar con el servidor.';

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

    final client = _buildClient();
    try {
      final response = await client
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
    } catch (e) {
      throw ApiException(_debugError(e));
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> get(
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
    final client = _buildClient();
    try {
      final response = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data as Map<String, dynamic>;
      }
      final detail = data is Map
          ? (data['message'] ?? data['detail'] ?? 'Error desconocido')
          : 'Error desconocido';
      throw ApiException(detail.toString(), statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_debugError(e));
    } finally {
      client.close();
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

    final client = _buildClient();
    try {
      final response = await client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 60)); // tiempo extra para FFmpeg

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
    } catch (e) {
      throw ApiException(_debugError(e));
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final client = _buildClient();
    try {
      final response = await client
          .patch(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 204) return {};

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data as Map<String, dynamic>;
      }
      final detail = data is Map
          ? (data['message'] ?? data['detail'] ?? 'Error desconocido')
          : 'Error desconocido';
      throw ApiException(detail.toString(), statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_debugError(e));
    } finally {
      client.close();
    }
  }

  static Future<void> delete(
    String path, {
    String? token,
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final client = _buildClient();
    try {
      final response = await client
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) return;

      final data = jsonDecode(response.body);
      final detail = data is Map
          ? (data['message'] ?? data['detail'] ?? 'Error desconocido')
          : 'Error desconocido';
      throw ApiException(detail.toString(), statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_debugError(e));
    } finally {
      client.close();
    }
  }
}
