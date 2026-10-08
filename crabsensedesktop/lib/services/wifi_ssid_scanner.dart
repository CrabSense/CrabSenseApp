import 'dart:io';

/// Scan nearby Wi-Fi SSIDs on the Owner PC. Password is never sent here.
class WifiSsidScanner {
  static Future<List<String>> scan() async {
    if (!Platform.isWindows) {
      return const [];
    }

    try {
      final result = await Process.run(
        'netsh',
        ['wlan', 'show', 'networks', 'mode=bssid'],
        runInShell: true,
      );
      if (result.exitCode != 0) {
        return const [];
      }

      final names = <String>{};
      final re = RegExp(r'^\s*SSID\s+\d+\s*:\s*(.+)\s*$', multiLine: true);
      for (final match in re.allMatches(result.stdout.toString())) {
        final ssid = match.group(1)?.trim() ?? '';
        if (ssid.isNotEmpty && ssid != 'SSID') {
          names.add(ssid);
        }
      }
      final list = names.toList()
        ..sort((a, b) {
          final rank = _rank(a).compareTo(_rank(b));
          if (rank != 0) return rank;
          return a.toLowerCase().compareTo(b.toLowerCase());
        });
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Farm Wi-Fi first. The board's own setup AP is not a network it can join.
  static int _rank(String name) {
    final n = name.toLowerCase();
    if (n == 'crabsense-c115') return 3;
    if (n == 'crabsense') return 0;
    if (n.startsWith('crabsense')) return 1;
    return 2;
  }
}
