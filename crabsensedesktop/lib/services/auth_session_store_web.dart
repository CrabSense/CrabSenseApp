// Development-only browser session store. Never use persistent localStorage.
import 'dart:convert';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../models/auth_models.dart';

class AuthSessionStore {
  static final _key = Uri.base.path.startsWith('/CrabSenseApp/')
      ? 'crabsense.desktop.pages.test.session' : 'crabsense.desktop.preview.session';

  Map<String, dynamic>? _read() {
    try {
      final value = html.window.sessionStorage[_key];
      if (value == null) return null;
      final raw = jsonDecode(value);
      return raw is Map ? Map<String, dynamic>.from(raw) : null;
    } catch (_) {
      return null;
    }
  }

  void _write(Map<String, dynamic> value) {
    try {
      html.window.sessionStorage[_key] = jsonEncode(value);
    } catch (_) {
      // Browser storage can be disabled. Login remains usable in memory.
    }
  }

  Future<bool> exists() async => _read() != null;

  Future<void> save(AuthSession session, {String? username}) async {
    _write({
      ...session.toJson(),
      'username': username ?? session.user.username ?? session.user.email,
    });
  }

  Future<void> saveIfPersisted(AuthSession session) async {
    if (await exists()) await save(session);
  }

  Future<({AuthSession session, String? username})?> load() async {
    try {
      final map = _read();
      if (map == null) return null;
      final session = AuthSession.fromJson(map);
      if (session.token.trim().isEmpty) return null;
      final username = (map['username'] ?? session.user.username)?.toString();
      return (session: session, username: username == null || username.isEmpty ? null : username);
    } catch (_) {
      return null;
    }
  }

  Future<String?> loadUsername() async {
    final name = _read()?['username']?.toString().trim();
    return name == null || name.isEmpty ? null : name;
  }

  Future<void> saveUsername(String username) async {
    _write({...?_read(), 'username': username.trim()});
  }

  Future<void> clear() async {
    try { html.window.sessionStorage.remove(_key); } catch (_) {}
  }

  Future<void> clearTokensKeepUsername() async {
    final username = await loadUsername();
    await clear();
    if (username != null) await saveUsername(username);
  }
}
