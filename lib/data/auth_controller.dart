import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:google_calendar_display/domain/app_config.dart';
import 'package:google_calendar_display/oauth/desktop_auth.dart'
    as desktop_auth;

const List<String> calendarScopes = [
  calendar.CalendarApi.calendarReadonlyScope,
];

class AuthController {
  AuthController(this.config)
    : _googleSignIn = GoogleSignIn(
        scopes: calendarScopes,
        clientId: kIsWeb ? config.oauthWebClientId : null,
      );

  final AppConfig config;
  final GoogleSignIn _googleSignIn;
  auth.AuthClient? _client;
  String? errorMessage;

  auth.AuthClient? get client => _client;
  bool get isSignedIn => _client != null;

  bool get _useDesktopFlow {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  Future<void> init() async {
    errorMessage = null;
    try {
      if (_useDesktopFlow) {
        _client = await DesktopOAuthStorage(config).restore();
      } else {
        await _googleSignIn.signInSilently();
        _client = await _googleSignIn.authenticatedClient();
      }
    } catch (error) {
      errorMessage = '로그인 정보를 확인하지 못했습니다.';
    }
  }

  Future<void> signIn(BuildContext context) async {
    errorMessage = null;
    try {
      if (_useDesktopFlow) {
        _client = await DesktopOAuthStorage(config).signIn(context);
      } else {
        final account = await _googleSignIn.signIn();
        if (account == null) {
          return;
        }
        _client = await _googleSignIn.authenticatedClient();
      }
    } catch (error) {
      errorMessage = '로그인에 실패했습니다. OAuth 설정을 확인해주세요.';
    }
  }

  Future<void> signOut() async {
    errorMessage = null;
    if (_useDesktopFlow) {
      await DesktopOAuthStorage(config).clear();
    } else {
      await _googleSignIn.signOut();
    }
    _client?.close();
    _client = null;
  }

  void dispose() {
    _client?.close();
  }
}

class DesktopOAuthStorage {
  DesktopOAuthStorage(this.config);

  final AppConfig config;
  static const String _prefsKey = 'desktop_oauth_credentials';

  auth.ClientId _clientId() {
    return auth.ClientId(
      config.oauthDesktopClientId,
      config.oauthDesktopClientSecret,
    );
  }

  Future<auth.AuthClient?> restore() async {
    if (config.oauthDesktopClientId.isEmpty ||
        config.oauthDesktopClientSecret.isEmpty) {
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      return null;
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final accessToken = auth.AccessToken(
      data['type'] as String,
      data['data'] as String,
      DateTime.parse(data['expiry'] as String),
    );
    final credentials = auth.AccessCredentials(
      accessToken,
      data['refreshToken'] as String?,
      (data['scopes'] as List<dynamic>).cast<String>(),
    );
    return desktop_auth.desktopAutoRefreshingClient(
      _clientId(),
      credentials,
      http.Client(),
    );
  }

  Future<auth.AuthClient> signIn(BuildContext context) async {
    if (config.oauthDesktopClientId.isEmpty ||
        config.oauthDesktopClientSecret.isEmpty) {
      throw Exception('Desktop OAuth 클라이언트 정보가 필요합니다.');
    }
    final client = await desktop_auth.desktopClientViaUserConsent(
      _clientId(),
      calendarScopes,
      (url) async {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        final code = await _promptForAuthCode(context, url);
        if (code.isEmpty) {
          throw Exception('인증 코드를 입력하지 않았습니다.');
        }
        return code;
      },
    );
    await _save(client.credentials);
    return client;
  }

  Future<String> _promptForAuthCode(BuildContext context, String url) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Google 인증 코드 입력'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('브라우저에서 로그인 후 인증 코드를 입력해주세요.'),
              const SizedBox(height: 8),
              SelectableText(url),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: '인증 코드'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(''),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
    return result?.trim() ?? '';
  }

  Future<void> _save(auth.AccessCredentials credentials) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'type': credentials.accessToken.type,
      'data': credentials.accessToken.data,
      'expiry': credentials.accessToken.expiry.toIso8601String(),
      'refreshToken': credentials.refreshToken,
      'scopes': credentials.scopes,
    };
    await prefs.setString(_prefsKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
