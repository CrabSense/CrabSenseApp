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
        ['wlan', 'show', 'networks'],
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
      final list = names.toList()..sort();
      return list;
    } catch (_) {
      return const [];
    }
  }
}
