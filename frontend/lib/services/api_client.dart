import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'api_exception.dart';

/// Single place where the app talks to the server.
///
/// Every server response is wrapped in the same envelope:
///
/// ```json
/// {"success": true,  "data": { ... }}
/// {"success": false, "error": {"code": "...", "message": "..."}}
/// ```
///
/// Callers never see that wrapper. They get `data` back, or an [ApiException]
/// carrying the server's own `code` and Korean `message`.
import '../models/user.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String _tokenKey = 'access_token';

  String? _accessToken;
  User? currentUser;

  /// Called when the server rejects our token. Set this once at startup to
  /// send the user back to the login screen.
  void Function()? onUnauthorized;

  bool get isLoggedIn => _accessToken != null;

  /// Restores the saved token and user info. Call once during app startup.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
    final email = prefs.getString('user_email');
    if (email != null && email.isNotEmpty) {
      currentUser = User(
        id: prefs.getString('user_id') ?? '1',
        email: email,
        nickname: prefs.getString('user_nickname'),
        photoUrl: prefs.getString('user_photo_url'),
      );
    }
  }

  Future<void> setToken(String? token, {User? user}) async {
    _accessToken = token;
    if (user != null) {
      currentUser = user;
    }
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      currentUser = null;
      await prefs.remove(_tokenKey);
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_nickname');
      await prefs.remove('user_photo_url');
    } else {
      await prefs.setString(_tokenKey, token);
      if (currentUser != null) {
        await prefs.setString('user_id', currentUser!.id.toString());
        await prefs.setString('user_email', currentUser!.email);
        if (currentUser!.nickname != null) {
          await prefs.setString('user_nickname', currentUser!.nickname!);
        }
        if (currentUser!.photoUrl != null) {
          await prefs.setString('user_photo_url', currentUser!.photoUrl!);
        }
      }
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? query, Duration? timeout}) =>
      _send('GET', path, query: query, timeout: timeout);

  Future<dynamic> post(String path, {Object? body, Duration? timeout}) =>
      _send('POST', path, body: body, timeout: timeout);

  Future<dynamic> put(String path, {Object? body, Duration? timeout}) =>
      _send('PUT', path, body: body, timeout: timeout);

  Future<dynamic> delete(String path, {Object? body, Duration? timeout}) =>
      _send('DELETE', path, body: body, timeout: timeout);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    Duration? timeout,
    int maxRetries = 3,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: query?.isEmpty ?? true ? null : query);

    Object? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final request = http.Request(method, uri);
      request.headers['Accept'] = 'application/json';
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }
      if (body != null) {
        // charset must be spelled out. Nicknames and error messages are Korean,
        // and without it some proxies fall back to latin-1 and mangle them.
        request.headers['Content-Type'] = 'application/json; charset=utf-8';
        request.bodyBytes = utf8.encode(jsonEncode(body));
      }

      try {
        final streamed =
            await request.send().timeout(timeout ?? ApiConfig.timeout);
        final response = await http.Response.fromStream(streamed);

        // If Render server returns 503 while cold starting, retry up to maxRetries
        if (response.statusCode == 503 && attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }

        return _unwrap(response);
      } on TimeoutException catch (e) {
        lastException = e;
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
      } on SocketException catch (e) {
        lastException = e;
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
      } on http.ClientException catch (e) {
        lastException = e;
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
      }
    }

    if (lastException is TimeoutException) {
      throw const ApiException(
          ApiException.timeout, '서버 응답이 없어요. 잠시 후 다시 시도해 주세요.');
    } else if (lastException is SocketException ||
        lastException is http.ClientException) {
      throw const ApiException(
          ApiException.networkError, '네트워크에 연결할 수 없어요. 연결 상태를 확인해 주세요.');
    }

    throw const ApiException(
        ApiException.timeout, '서버 응답이 없어요. 잠시 후 다시 시도해 주세요.');
  }

  dynamic _unwrap(http.Response response) {
    // Decode the raw bytes ourselves. `response.body` guesses latin-1 when the
    // server omits a charset, which turns every Korean message into mojibake.
    final text = utf8.decode(response.bodyBytes, allowMalformed: true);

    Map<String, dynamic>? envelope;
    if (text.isNotEmpty) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          envelope = decoded;
        }
      } on FormatException {
        // Not JSON. Handled below alongside the status code.
      }
    }

    if (envelope == null) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 204 and friends. Nothing to hand back.
        return null;
      }
      if (response.statusCode == 503) {
        throw const ApiException(ApiException.aiServiceUnavailable,
            '현재 AI 분석을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요.');
      }
      throw ApiException(ApiException.malformedResponse,
          '서버 응답을 이해할 수 없어요. (HTTP ${response.statusCode})');
    }

    if (envelope['success'] == true) {
      return envelope['data'];
    }

    final error = envelope['error'];
    final code = (error is Map && error['code'] is String)
        ? error['code'] as String
        : ApiException.malformedResponse;
    final message = (error is Map && error['message'] is String)
        ? error['message'] as String
        : '알 수 없는 오류가 발생했어요.';

    if (code == ApiException.unauthorized) {
      // The token is dead. Drop it so the next launch goes straight to login
      // instead of retrying with a credential we already know is rejected.
      unawaited(setToken(null));
      onUnauthorized?.call();
    }

    throw ApiException(code, message);
  }
}
