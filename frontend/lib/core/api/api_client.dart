// The single HTTP client for the whole app. It:
//   1. adds the JWT to every request,
//   2. unwraps the backend's { success, message, data } envelope,
//   3. turns failures into an ApiException with a readable message,
//   4. calls onUnauthorized (log out) when the server answers 401.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// A failed request, with a message that is safe to show to the user.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;

  /// Per-field messages from the server, e.g. {"email": "Enter a valid email"}.
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

/// What a successful call returns: the "data" value and the "message".
class ApiResult {
  const ApiResult(this.data, this.message);
  final dynamic data;
  final String message;
}

class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Set after login, cleared on logout.
  String? token;

  /// Called when the server says the token is missing, wrong or expired.
  void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 12);

  Future<ApiResult> get(String path, {Map<String, String?>? query}) =>
      _send('GET', path, query: query);
  Future<ApiResult> post(String path, {Object? body}) => _send('POST', path, body: body);
  Future<ApiResult> patch(String path, {Object? body}) => _send('PATCH', path, body: body);
  Future<ApiResult> delete(String path) => _send('DELETE', path);

  Future<ApiResult> _send(String method, String path,
      {Object? body, Map<String, String?>? query}) async {
    // Drop empty filters so the URL stays clean.
    final cleaned = <String, String>{
      for (final e in (query ?? {}).entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path')
        .replace(queryParameters: cleaned.isEmpty ? null : cleaned);

    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request).timeout(_timeout));
    } on TimeoutException {
      throw ApiException('The server took too long to answer. Please try again.');
    } catch (_) {
      // No network, server not running, CORS failure...
      throw ApiException('Could not reach the FoodLoop server. Check that it is running.');
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('The server sent an unexpected reply.', statusCode: response.statusCode);
    }

    final message = (json['message'] ?? '').toString();
    if (response.statusCode >= 200 && response.statusCode < 300 && json['success'] == true) {
      return ApiResult(json['data'], message);
    }

    // A 401 on a logged-in request means the session is no longer valid.
    if (response.statusCode == 401 && token != null) onUnauthorized?.call();

    final data = json['data'];
    final errors = (data is Map && data['errors'] is Map)
        ? (data['errors'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
        : const <String, String>{};
    throw ApiException(
      message.isEmpty ? 'Something went wrong.' : message,
      statusCode: response.statusCode,
      fieldErrors: errors,
    );
  }
}
