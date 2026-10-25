import 'package:flutter/services.dart';

/// Ép ô nhập về ASCII khi bộ gõ Telex (UniKey/EVKey) chen vào.
///
/// Gõ `owner` trong khi bật tiếng Việt: Telex hiểu `ow` là `ơ` nên ô nhập thành
/// `ơner` và đăng nhập sai dù gõ đúng. Formatter trả các chữ bị Telex ghép về
/// đúng phím gốc (`ơ` → `ow`) và bỏ toàn bộ dấu thanh, nên `ơner` → `owner`.
///
/// ponytail: Telex có nhiều phím cho cùng một chữ (ơ = ow / o[ / o7, ư = uw / w).
/// Ở đây chỉ khôi phục phím `w` — đúng với mặc định UniKey/EVKey. Kiểu gõ VNI
/// hoặc `o[` vẫn mất chữ đó thay vì dựng lại. Dấu thanh do `s f r x j` cũng
/// không dựng lại được vì bộ gõ đã "ăn" phím đó rồi.
class AsciiTextInputFormatter extends TextInputFormatter {
  const AsciiTextInputFormatter();

  /// Mỗi nhóm: các biến thể có dấu của cùng một chữ → phím Telex gốc.
  /// Phần tử đầu tiên là chữ không dấu.
  static const _groups = <(String, String)>[
    ('aáàảãạ', 'a'),
    ('ăắằẳẵặ', 'aw'),
    ('âấầẩẫậ', 'aa'),
    ('eéèẻẽẹ', 'e'),
    ('êếềểễệ', 'ee'),
    ('iíìỉĩị', 'i'),
    ('oóòỏõọ', 'o'),
    ('ôốồổỗộ', 'oo'),
    ('ơớờởỡợ', 'ow'),
    ('uúùủũụ', 'u'),
    ('ưứừửữự', 'uw'),
    ('yýỳỷỹỵ', 'y'),
    ('d', 'd'),
    ('đ', 'dd'),
  ];

  static final Map<String, String> _map = _buildMap();

  static Map<String, String> _buildMap() {
    final map = <String, String>{};
    for (final (chars, keys) in _groups) {
      for (var i = 0; i < chars.length; i++) {
        final lower = chars[i];
        map[lower] = keys;
        map[lower.toUpperCase()] = keys[0].toUpperCase() + keys.substring(1);
      }
    }
    return map;
  }

  /// Trả `null` nếu chuỗi không có ký tự tiếng Việt nào.
  static String? toAscii(String input) {
    final out = StringBuffer();
    var changed = false;
    for (var i = 0; i < input.length; i++) {
      final replacement = _map[input[i]];
      if (replacement != null && replacement != input[i]) changed = true;
      out.write(replacement ?? input[i]);
    }
    return changed ? out.toString() : null;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final source = newValue.text;
    final cursor = newValue.selection.baseOffset;
    final out = StringBuffer();
    var newCursor = 0;
    for (var i = 0; i < source.length; i++) {
      if (i == cursor) newCursor = out.length;
      out.write(_map[source[i]] ?? source[i]);
    }
    final text = out.toString();
    if (text == source) return newValue;
    if (cursor >= source.length) newCursor = text.length;
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: newCursor),
      composing: TextRange.empty,
    );
  }
}
