import 'dart:convert';
import 'dart:io';

import '../models/auth_models.dart';

/// Lưu JWT + khu đang chọn trên máy (Windows: %APPDATA%\CrabSense).
class AuthSessionStore {
  static const _fileName = 'auth_session.json';

  Future<File> _file() async {
    final root = Platform.environment['APPDATA'] ??
        Platform.environment['HOME'] ??
        Directory.systemTemp.path;
    final dir = Directory('$root${Platform.pathSeparator}CrabSense');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<bool> exists() async {
    try {
      return await (await _file()).exists();
    } catch (_) {
      return false;
    }
  }

  Future<void> save(AuthSession session, {String? username}) async {
    final file = await _file();
    final payload = {
      ...session.toJson(),
      'username': username ?? session.user.username ?? session.user.email,
    };
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<void> saveIfPersisted(AuthSession session) async {
    if (await exists()) {
      await save(session);
    }
  }

  Future<({AuthSession session, String? username})?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map) return null;
      final map = Map<String, dynamic>.from(raw);
      final session = AuthSession.fromJson(map);
      if (session.token.trim().isEmpty) return null;
      final username = (map['username'] ?? session.user.username)?.toString();
      return (
        session: session,
        username: username == null || username.isEmpty ? null : username,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> loadUsername() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map) return null;
      final username = raw['username']?.toString().trim();
      return username == null || username.isEmpty ? null : username;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUsername(String username) async {
    try {
      final file = await _file();
      Map<String, dynamic> map = {};
      if (await file.exists()) {
        final raw = jsonDecode(await file.readAsString());
        if (raw is Map) map = Map<String, dynamic>.from(raw);
      }
      map['username'] = username.trim();
      await file.writeAsString(jsonEncode(map), flush: true);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Xóa token, giữ tên đăng nhập cho form login.
  Future<void> clearTokensKeepUsername() async {
    final username = await loadUsername();
    await clear();
    if (username != null) await saveUsername(username);
  }
}
