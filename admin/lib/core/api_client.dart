import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import 'config.dart';

/// Thin typed wrapper around the Ghost Telemetry HTTP API.
///
/// Handles bearer-token attachment, optional refresh-on-401 and JSON
/// encoding/decoding so the UI layer works with already-parsed [Map]s/`List`s.
class ApiClient {
  ApiClient({String? token}) : _token = token;

  String? _token;
  final http.Client _client = http.Client();

  /// Called when the backend rejects the access token so the app can attempt a
  /// refresh or force a re-login.
  Future<String?> Function()? onUnauthorized;

  String? get token => _token;
  set token(String? t) => _token = t;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(AppConfig.backendUrl);
    final q = query == null || query.isEmpty
        ? ''
        : '?${Uri(queryParameters: query).query}';
    return Uri.parse('$base$path$q');
  }

  Map<String, String> _headers({bool json = true}) => {
    if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    if (json) 'Content-Type': 'application/json',
  };

  dynamic _decode(http.Response res) {
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  Never _error(http.Response res) {
    var message = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) {
        final m = body['message'];
        message = m is List ? m.join(', ') : m.toString();
      } else if (body is Map && body['error'] != null) {
        message = body['error'].toString();
      }
    } catch (_) {}
    throw ApiException(message, statusCode: res.statusCode);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    return _request(
      () => _client
          .get(_uri(path, query), headers: _headers())
          .timeout(const Duration(seconds: 15)),
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    bool retryOnUnauthorized = true,
  }) async {
    return _request(
      () => _client
          .post(
            _uri(path),
            headers: _headers(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15)),
      retry: retryOnUnauthorized,
    );
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    return _request(
      () => _client
          .patch(
            _uri(path),
            headers: _headers(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15)),
    );
  }

  Future<dynamic> delete(String path) async {
    return _request(
      () => _client
          .delete(_uri(path), headers: _headers())
          .timeout(const Duration(seconds: 15)),
    );
  }

  Future<dynamic> _request(
    Future<http.Response> Function() request, {
    bool retry = true,
  }) async {
    final res = await request();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return _decode(res);
    }
    if (retry && res.statusCode == 401 && onUnauthorized != null) {
      final newToken = await onUnauthorized!();
      if (newToken != null && newToken.isNotEmpty) {
        _token = newToken;
        return _request(request, retry: false);
      }
    }
    return _error(res);
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}
