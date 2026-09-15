import 'dart:convert';

import 'package:crab_farm_monitor_desktop/services/cloud_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// `tokenExpired` quyết định app có được vào bằng session cache khi BE không
/// gọi được hay không. Sai ở đây thì app vào dashboard bằng token chết, mọi API
/// trả 401 và màn hình chỉ toàn lỗi kết nối — đúng lỗi đã gặp khi BE chưa bật.
void main() {
  /// JWT giả: chỉ payload quan trọng, chữ ký để trống.
  String jwt(Map<String, Object?> claims) {
    String seg(Object json) =>
        base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
    return '${seg({'alg': 'HS256', 'typ': 'JWT'})}.${seg(claims)}.sig';
  }

  group('CloudAuthService.tokenExpired', () {
    test('token còn hạn => false', () {
      final future = DateTime.now().add(const Duration(hours: 1));
      expect(
        CloudAuthService.tokenExpired(jwt({'exp': future.millisecondsSinceEpoch ~/ 1000})),
        isFalse,
      );
    });

    test('token quá hạn => true', () {
      final past = DateTime.now().subtract(const Duration(minutes: 1));
      expect(
        CloudAuthService.tokenExpired(jwt({'exp': past.millisecondsSinceEpoch ~/ 1000})),
        isTrue,
      );
    });

    test('JWT thật đã hết hạn (token cache hôm qua) => true', () {
      // exp = 13/09/2026 17:03:11 UTC — đúng token thật đã gây lỗi 401 lặp mỗi 2s.
      expect(CloudAuthService.tokenExpired(jwt({'exp': 1789318991})), isTrue);
    });

    test('đọc được exp khi payload có padding bị cắt', () {
      // base64url không padding là dạng JWT chuẩn; exp ~2030 nên còn hạn.
      final token = jwt({'sub': 'owner', 'exp': 1900000000});
      expect(token.split('.')[1].contains('='), isFalse);
      expect(CloudAuthService.tokenExpired(token), isFalse);
    });

    test('token hỏng / thiếu exp => coi như hết hạn', () {
      expect(CloudAuthService.tokenExpired(''), isTrue);
      expect(CloudAuthService.tokenExpired('khong-phai-jwt'), isTrue);
      expect(CloudAuthService.tokenExpired('a.b'), isTrue);
      expect(CloudAuthService.tokenExpired('a.@@@khong-phai-base64@@@.c'), isTrue);
      expect(CloudAuthService.tokenExpired(jwt({'sub': 'owner'})), isTrue);
      expect(CloudAuthService.tokenExpired(jwt({'exp': 'khong-phai-so'})), isTrue);
    });
  });
}
